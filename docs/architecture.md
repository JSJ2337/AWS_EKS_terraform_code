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
                subgraph EKS["EKS Cluster (Fargate)"]
                    direction LR
                    FG_A[Fargate Pods<br/>AZ-a]
                    FG_C[Fargate Pods<br/>AZ-c]
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

## 멀티 어카운트 구조 (AWS Landing Zone)

```mermaid
flowchart TB
    subgraph Org["AWS Organization (Root)"]
        Management["Management Account<br/>- Organizations<br/>- IAM Identity Center<br/>- SCPs<br/>- Billing"]

        subgraph SecurityOU["Security OU"]
            LogArchive["Log Archive Account<br/>- CloudTrail Logs<br/>- Config Logs<br/>- VPC Flow Logs"]
            Audit["Audit Account<br/>- Security Hub<br/>- GuardDuty<br/>- Config Aggregator"]
        end

        subgraph InfraOU["Infrastructure OU"]
            Network["Network Account<br/>- Transit Gateway<br/>- Network Firewall<br/>- Route 53"]
            Shared["Shared Services Account<br/>- ECR<br/>- Terraform State<br/>- CI/CD Pipeline"]
        end

        subgraph SandboxOU["Sandbox OU"]
            Sandbox["Sandbox Account<br/>- 실험/테스트"]
        end

        subgraph WorkloadOU["Workloads OU"]
            Prod["Production Account<br/>- EKS Cluster<br/>- RDS/Redis<br/>- Application"]
            Stg["Staging Account"]
            Dev["Development Account"]
        end
    end

    Management --> SecurityOU
    Management --> InfraOU
    Management --> SandboxOU
    Management --> WorkloadOU

    LogArchive -.->|Logs| Prod
    LogArchive -.->|Logs| Stg
    LogArchive -.->|Logs| Dev
    Audit -.->|Security Monitoring| Prod
    Network -.->|Transit Gateway| Prod
    Shared -.->|ECR/State| Prod
    Shared -.->|ECR/State| Stg
    Shared -.->|ECR/State| Dev
```

### 계정별 역할

| 계정 | OU | 주요 역할 |
| ---- | -- | --------- |
| Management | Root | Organizations, IAM Identity Center, SCPs, Billing |
| Log Archive | Security | 중앙 로그 저장 (CloudTrail, Config, Flow Logs) |
| Audit | Security | 보안 모니터링 (Security Hub, GuardDuty) |
| Network | Infrastructure | 네트워크 허브 (Transit Gateway, Firewall) |
| Shared Services | Infrastructure | 공유 리소스 (ECR, State, CI/CD) |
| Sandbox | Sandbox | 개발자 실험 환경 |
| Production | Workloads | 프로덕션 워크로드 |
| Staging | Workloads | 스테이징 환경 |
| Development | Workloads | 개발 환경 |

## 레이어 구조

### 배포 순서 및 의존성

```mermaid
flowchart TD
    F[00-foundation] --> IAM[04-iam]
    IAM --> CW[05-cloudwatch]
    CW --> N[10-networking]
    N --> S[20-security]
    S --> EKS[30-eks-cluster]
    EKS --> FG[40-fargate]
    FG --> AD[50-addons]

    AD --> ARGO[55-argocd]
    AD --> LATTICE[56-vpc-lattice]
    AD --> DB[60-database]
    AD --> CA[70-cache]
    AD --> ST[80-storage]

    ARGO --> APPS[Applications via ArgoCD]
    LATTICE --> APPS

    DB --> MO[90-monitoring]
    CA --> MO
    ST --> MO

    IAM -.->|IAM Roles| N
    IAM -.->|IAM Roles| S
    N -.->|VPC Endpoints| MO
    S -.->|Security Groups| MO
    CW -.->|Log Groups| EKS
```

### 레이어별 설명

| 레이어 | 목적 | 주요 리소스 |
| ------ | ---- | ----------- |
| 00-foundation | AWS 기본 설정 | KMS, S3 State Bucket |
| 04-iam | IAM 역할 중앙 관리 | EKS Cluster Role, Fargate Pod Execution Role, Flow Logs Role, RDS Monitoring Role |
| 05-cloudwatch | CloudWatch 로그 그룹 | EKS, ECS, EC2, Lambda, VPC Log Groups |
| 10-networking | 네트워크 인프라 | VPC, Subnet, NAT GW, Route Table |
| 20-security | 보안 설정 | Security Group |
| 30-eks-cluster | EKS 컨트롤 플레인 | EKS Cluster, OIDC Provider |
| 40-fargate | Fargate Profiles | System, Application, Monitoring Profiles |
| 50-addons | EKS 애드온 | VPC CNI, CoreDNS, kube-proxy, IRSA |
| 55-argocd | GitOps CD | ArgoCD (Helm), App of Apps |
| 56-vpc-lattice | 서비스 메시 | VPC Lattice Service Network, Services, Target Groups |
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
```

### 서브넷 구성

| 서브넷 유형 | CIDR | 용도 |
| ----------- | ---- | ---- |
| Public | 10.0.0.0/24, 10.0.1.0/24 | NAT GW, ALB, Bastion |
| Private | 10.0.10.0/24, 10.0.11.0/24 | EKS Fargate Pods |
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

## EKS 클러스터 구성 (Fargate 전용)

```mermaid
flowchart TB
    subgraph EKSCluster["EKS Cluster (jsj-eks-cluster v1.31)"]
        subgraph ControlPlane["Control Plane (AWS Managed)"]
            API[API Server]
            ETCD[(etcd)]
            CM[Controller Manager]
            SCH[Scheduler]
        end

        subgraph DataPlane["Data Plane (Fargate)"]
            subgraph SystemFG["System Profile"]
                SYS1[kube-system<br/>argocd]
            end

            subgraph AppFG["Application Profile"]
                APP1[default<br/>app, staging]
            end

            subgraph MonFG["Monitoring Profile"]
                MON1[prometheus<br/>grafana, loki]
            end
        end
    end

    subgraph Addons["EKS Add-ons"]
        CNI[VPC CNI]
        DNS[CoreDNS]
        PROXY[kube-proxy]
        POD_ID[Pod Identity]
    end

    ControlPlane --> DataPlane
    DataPlane --> Addons
```

### Fargate Profile 설정

| Profile | Namespace | 용도 |
| ------- | --------- | ---- |
| system | kube-system, argocd | 시스템 컴포넌트 |
| application | default, app, staging | 애플리케이션 워크로드 |
| monitoring | prometheus, grafana, loki | 모니터링 (선택적) |

### 현재 EKS 애드온

| 애드온 | 상태 | 비고 |
| ------ | ---- | ---- |
| vpc-cni | Active | Fargate 네트워킹 |
| coredns | Active | Fargate에서 실행 |
| kube-proxy | Active | DaemonSet |
| eks-pod-identity-agent | Active | IRSA 대체 |

### AWS Load Balancer Controller

AWS Load Balancer Controller는 Kubernetes Ingress/Service를 AWS ALB/NLB로 프로비저닝합니다.

```mermaid
flowchart LR
    subgraph EKS["EKS Cluster"]
        LBC[AWS LB Controller]
        Ingress[Ingress Resource]
        SVC[Service]
        Pod[Pods]
    end

    subgraph AWS["AWS"]
        ALB[Application LB]
        TG[Target Group]
    end

    LBC -->|Watch| Ingress
    LBC -->|Create| ALB
    LBC -->|Register| TG
    ALB --> TG
    TG --> Pod
```

| 항목 | 설정 |
| ---- | ---- |
| 설치 방식 | Helm (Terraform 관리) |
| IAM 연동 | IRSA (OIDC) |
| Ingress Class | alb |
| Target Type | ip (Fargate 필수) |

### ArgoCD (GitOps)

ArgoCD는 GitOps 방식으로 Kubernetes 애플리케이션을 배포합니다.

```mermaid
flowchart TB
    subgraph Git["Git Repository"]
        Manifests[K8s Manifests]
    end

    subgraph EKS["EKS Cluster"]
        ArgoCD[ArgoCD Server]
        App[Application CRD]
        Deploy[Deployments]
    end

    subgraph AWS["AWS"]
        ALB[ALB Ingress]
    end

    User((User)) --> ALB
    ALB --> ArgoCD
    ArgoCD -->|Watch| Manifests
    ArgoCD -->|Sync| App
    App --> Deploy
```

| 항목 | 설정 |
| ---- | ---- |
| 네임스페이스 | argocd |
| 설치 방식 | Helm (Terraform 관리) |
| 외부 접속 | ALB Ingress (Host: *) |
| Ingress 관리 | Terraform kubernetes_ingress_v1 |

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
```

## 보안 설계

### IAM 구조

```mermaid
flowchart TB
    subgraph IAM_Layer["04-iam Layer"]
        subgraph ClusterRoles["EKS Roles"]
            CR[EKS Cluster Role]
            FG[Fargate Pod Execution Role]
        end

        subgraph ServiceRoles["Service Roles"]
            FL[VPC Flow Logs Role]
            RDS_MON[RDS Monitoring Role]
        end

        subgraph UserRoles["User Roles"]
            Admin[EKS Admin Role]
        end
    end

    subgraph Addons_Layer["50-addons Layer (IRSA)"]
        subgraph IRSA["IRSA (Pod IAM)"]
            LBC_SA[LB Controller SA]
        end
    end

    OIDC[OIDC Provider] --> IRSA
    CR --> EKS[EKS Cluster]
    FG --> Fargate[Fargate Pods]
    FL --> VPC[VPC Flow Logs]
    RDS_MON --> RDS[RDS Enhanced Monitoring]
```

### 네트워크 보안

```mermaid
flowchart LR
    Internet((Internet)) --> ALB_SG

    subgraph SecurityGroups["Security Groups"]
        ALB_SG[ALB SG<br/>443, 80]
        Pod_SG[Pods SG<br/>All from ALB]
        RDS_SG[RDS SG<br/>3306 from Pods]
        Redis_SG[Redis SG<br/>6379 from Pods]
    end

    ALB_SG --> Pod_SG
    Pod_SG --> RDS_SG
    Pod_SG --> Redis_SG
```

## 고가용성

```mermaid
flowchart TB
    subgraph HA["High Availability Design"]
        subgraph AZa["AZ-a"]
            NAT1[NAT GW]
            Pod1[Fargate Pods]
            RDS1[(RDS Primary)]
            Redis1[(Redis Node)]
        end

        subgraph AZc["AZ-c"]
            NAT2[NAT GW]
            Pod2[Fargate Pods]
            RDS2[(RDS Standby)]
            Redis2[(Redis Node)]
        end
    end

    ALB[ALB] --> Pod1
    ALB --> Pod2
    RDS1 <-->|Sync| RDS2
    Redis1 <-->|Cluster| Redis2
```

### 고가용성 체크리스트

- Multi-AZ 배포 (최소 2개 AZ)
- EKS 컨트롤 플레인: AWS 관리형 HA
- Fargate: 다중 AZ 자동 분산
- RDS: Multi-AZ 옵션
- ElastiCache: Cluster Mode 활성화
- NAT Gateway: AZ별 배치
