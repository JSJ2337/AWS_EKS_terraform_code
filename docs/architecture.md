# 아키텍처 설계

AWS EKS 인프라의 전체 아키텍처를 설명합니다.

## 인프라 개요

```mermaid
flowchart TB
    subgraph AWS["AWS Cloud"]
        subgraph VPC["VPC (10.0.0.0/16)"]
            subgraph PublicSubnets["Public Subnets"]
                direction LR
                IGW[Internet Gateway]
                NAT_A[NAT Gateway<br/>AZ-a]
                NAT_C[NAT Gateway<br/>AZ-c]
                ALB[Application<br/>Load Balancer]
            end

            subgraph PrivateSubnets["Private Subnets"]
                subgraph EKS["EKS Cluster"]
                    direction LR
                    NG_A[Node Group<br/>AZ-a]
                    NG_C[Node Group<br/>AZ-c]
                end
            end

            subgraph DatabaseSubnets["Database Subnets"]
                direction LR
                RDS[(RDS Aurora<br/>MySQL)]
                Redis[(ElastiCache<br/>Redis)]
            end
        end

        subgraph AWSServices["AWS Services"]
            ECR[ECR]
            S3[S3]
            SM[Secrets<br/>Manager]
            CW[CloudWatch]
        end
    end

    Users((Users)) --> ALB
    ALB --> EKS
    EKS --> RDS
    EKS --> Redis
    EKS --> ECR
    EKS --> S3
    EKS --> SM
    EKS --> CW
    PrivateSubnets --> NAT_A
    PrivateSubnets --> NAT_C
    NAT_A --> IGW
    NAT_C --> IGW
```

## 멀티 어카운트 구조

```mermaid
flowchart TB
    subgraph Org["AWS Organization"]
        Management["Management Account<br/>- Organizations<br/>- IAM Identity Center<br/>- Billing"]

        subgraph SecurityOU["Security OU"]
            Security["Security Account<br/>- Security Hub<br/>- GuardDuty<br/>- CloudTrail"]
        end

        subgraph SharedOU["Shared Services OU"]
            Shared["Shared Services Account<br/>- ECR<br/>- Terraform State<br/>- Transit Gateway"]
        end

        subgraph WorkloadOU["Workload OU"]
            Prod["Production Account<br/>- EKS Cluster<br/>- RDS/Redis<br/>- Application"]
            Stg["Staging Account"]
            Dev["Development Account"]
        end
    end

    Management --> SecurityOU
    Management --> SharedOU
    Management --> WorkloadOU
    Shared -.->|Cross-Account| Prod
    Shared -.->|Cross-Account| Stg
    Shared -.->|Cross-Account| Dev
```

## 레이어 구조

### 배포 순서 및 의존성

```mermaid
flowchart TD
    F[00-foundation] --> N[10-networking]
    N --> S[20-security]
    S --> EKS[30-eks-cluster]
    EKS --> NG[40-nodegroups]
    NG --> AD[50-addons]

    AD --> DB[60-database]
    AD --> CA[70-cache]
    AD --> ST[80-storage]

    DB --> MO[90-monitoring]
    CA --> MO
    ST --> MO

    N -.->|VPC Endpoints| MO
    S -.->|Security Groups| MO

    style F fill:#e1f5fe
    style N fill:#b3e5fc
    style S fill:#81d4fa
    style EKS fill:#4fc3f7
    style NG fill:#29b6f6
    style AD fill:#03a9f4
    style DB fill:#039be5
    style CA fill:#039be5
    style ST fill:#039be5
    style MO fill:#0288d1
```

### 레이어별 설명

| 레이어 | 목적 | 주요 리소스 |
| ------ | ---- | ----------- |
| 00-foundation | AWS 기본 설정 | IAM, KMS, S3 State Bucket |
| 10-networking | 네트워크 인프라 | VPC, Subnet, NAT GW, Route Table |
| 20-security | 보안 설정 | Security Group, IAM Role, IRSA |
| 30-eks-cluster | EKS 컨트롤 플레인 | EKS Cluster, OIDC Provider |
| 40-nodegroups | 워커 노드 | Node Group, Launch Template |
| 50-addons | EKS 애드온 | VPC CNI, CoreDNS, kube-proxy |
| 60-database | 데이터베이스 | RDS, Parameter Group |
| 70-cache | 캐시 | ElastiCache Redis |
| 80-storage | 스토리지 | EBS CSI, EFS, S3 |
| 90-monitoring | 모니터링 | CloudWatch, Prometheus |

## 네트워크 설계

### VPC 구성도

```mermaid
flowchart TB
    subgraph VPC["VPC: 10.0.0.0/16"]
        subgraph AZa["Availability Zone A"]
            Pub_A["Public Subnet<br/>10.0.0.0/24"]
            Pri_A["Private Subnet<br/>10.0.10.0/24"]
            DB_A["Database Subnet<br/>10.0.20.0/24"]
            Pod_A["Pod Subnet<br/>10.0.100.0/22"]
        end

        subgraph AZc["Availability Zone C"]
            Pub_C["Public Subnet<br/>10.0.1.0/24"]
            Pri_C["Private Subnet<br/>10.0.11.0/24"]
            DB_C["Database Subnet<br/>10.0.21.0/24"]
            Pod_C["Pod Subnet<br/>10.0.104.0/22"]
        end
    end

    IGW[Internet Gateway] --> Pub_A
    IGW --> Pub_C

    NAT_A[NAT GW] --> Pub_A
    NAT_C[NAT GW] --> Pub_C

    Pri_A --> NAT_A
    Pri_C --> NAT_C

    style Pub_A fill:#c8e6c9
    style Pub_C fill:#c8e6c9
    style Pri_A fill:#fff9c4
    style Pri_C fill:#fff9c4
    style DB_A fill:#ffccbc
    style DB_C fill:#ffccbc
    style Pod_A fill:#e1bee7
    style Pod_C fill:#e1bee7
```

### 서브넷 구성

| 서브넷 유형 | CIDR | 용도 |
| ----------- | ---- | ---- |
| Public | 10.0.0.0/24, 10.0.1.0/24 | NAT GW, ALB, Bastion |
| Private | 10.0.10.0/24, 10.0.11.0/24 | EKS 워커 노드 |
| Database | 10.0.20.0/24, 10.0.21.0/24 | RDS, ElastiCache |
| Pod | 10.0.100.0/22, 10.0.104.0/22 | EKS Pod (CNI Custom) |

### EKS 서브넷 태그

```hcl
# Public Subnet
"kubernetes.io/role/elb" = "1"
"kubernetes.io/cluster/${cluster_name}" = "shared"

# Private Subnet
"kubernetes.io/role/internal-elb" = "1"
"kubernetes.io/cluster/${cluster_name}" = "shared"
```

## EKS 클러스터 구성

```mermaid
flowchart TB
    subgraph EKSCluster["EKS Cluster"]
        subgraph ControlPlane["Control Plane (AWS Managed)"]
            API[API Server]
            ETCD[(etcd)]
            CM[Controller Manager]
            SCH[Scheduler]
        end

        subgraph DataPlane["Data Plane"]
            subgraph SystemNG["System Node Group"]
                SYS1[m6i.large]
                SYS2[m6i.large]
            end

            subgraph AppNG["Application Node Group"]
                APP1[m6i.xlarge]
                APP2[m6i.xlarge]
                APP3[m6i.xlarge]
            end

            subgraph SpotNG["Spot Node Group"]
                SPOT1[m6i.xlarge<br/>Spot]
                SPOT2[m6i.xlarge<br/>Spot]
            end
        end
    end

    subgraph Addons["EKS Add-ons"]
        CNI[VPC CNI]
        DNS[CoreDNS]
        PROXY[kube-proxy]
        EBS[EBS CSI]
        LBC[AWS LB Controller]
        CA[Cluster Autoscaler]
    end

    ControlPlane --> DataPlane
    DataPlane --> Addons

    style ControlPlane fill:#e3f2fd
    style SystemNG fill:#fff3e0
    style AppNG fill:#e8f5e9
    style SpotNG fill:#fce4ec
```

## State 관리

```mermaid
flowchart LR
    subgraph StateBackend["Terraform State Backend"]
        subgraph S3["S3 Bucket"]
            Live["live/<br/>├── 00-foundation/<br/>├── 10-networking/<br/>├── 30-eks-cluster/<br/>└── ..."]
            Stg["stg/"]
            Dev["dev/"]
        end

        DDB[(DynamoDB<br/>State Lock)]
    end

    TG[Terragrunt] -->|read/write| S3
    TG -->|lock/unlock| DDB

    style S3 fill:#fff9c4
    style DDB fill:#e1bee7
```

## 보안 설계

### IAM 구조

```mermaid
flowchart TB
    subgraph IAM["IAM Structure"]
        subgraph ClusterRoles["EKS Cluster Roles"]
            CR[EKS Cluster Role]
            NR[Node Group Role]
        end

        subgraph IRSA["IRSA (Pod IAM)"]
            LBC_SA[LB Controller SA]
            CA_SA[Cluster Autoscaler SA]
            EBS_SA[EBS CSI SA]
            APP_SA[Application SA]
        end

        subgraph UserRoles["User Roles"]
            Admin[EKS Admin Role]
            Dev[Developer Role]
            RO[ReadOnly Role]
        end
    end

    OIDC[OIDC Provider] --> IRSA
    CR --> EKS[EKS Cluster]
    NR --> NG[Node Groups]

    style IRSA fill:#e8f5e9
    style ClusterRoles fill:#e3f2fd
    style UserRoles fill:#fff3e0
```

### 네트워크 보안

```mermaid
flowchart LR
    Internet((Internet)) --> ALB_SG

    subgraph SecurityGroups["Security Groups"]
        ALB_SG[ALB SG<br/>443, 80]
        Node_SG[Node SG<br/>All from ALB]
        RDS_SG[RDS SG<br/>3306 from Node]
        Redis_SG[Redis SG<br/>6379 from Node]
    end

    ALB_SG --> Node_SG
    Node_SG --> RDS_SG
    Node_SG --> Redis_SG

    style ALB_SG fill:#c8e6c9
    style Node_SG fill:#fff9c4
    style RDS_SG fill:#ffccbc
    style Redis_SG fill:#e1bee7
```

## 고가용성

```mermaid
flowchart TB
    subgraph HA["High Availability Design"]
        subgraph AZa["AZ-a"]
            NAT1[NAT GW]
            Node1[EKS Nodes]
            RDS1[(RDS Primary)]
            Redis1[(Redis Node)]
        end

        subgraph AZc["AZ-c"]
            NAT2[NAT GW]
            Node2[EKS Nodes]
            RDS2[(RDS Standby)]
            Redis2[(Redis Node)]
        end
    end

    ALB[ALB] --> Node1
    ALB --> Node2
    RDS1 <-->|Sync| RDS2
    Redis1 <-->|Cluster| Redis2

    style AZa fill:#e3f2fd
    style AZc fill:#e8f5e9
```

### 고가용성 체크리스트

- Multi-AZ 배포 (최소 2개 AZ)
- EKS 컨트롤 플레인: AWS 관리형 HA
- 워커 노드: 다중 AZ Node Group
- RDS: Multi-AZ 옵션
- ElastiCache: Cluster Mode 활성화
- NAT Gateway: AZ별 배치
