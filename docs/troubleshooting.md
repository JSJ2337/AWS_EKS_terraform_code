# 트러블슈팅 가이드

AWS EKS 인프라 운영 중 발생할 수 있는 문제와 해결 방법을 정리합니다.

## Terraform/Terragrunt 관련

### State Lock 문제

**증상:**

```text
Error: Error acquiring the state lock
```

**원인:**

- 이전 작업이 비정상 종료됨
- 동시에 여러 작업 실행

**해결:**

```bash
# DynamoDB에서 lock 확인
aws dynamodb scan --table-name ${project}-terraform-lock

# Lock 강제 해제 (주의: 다른 작업이 없는지 확인 필요)
terragrunt force-unlock <LOCK_ID>
```

### Provider 버전 충돌

**증상:**

```text
Error: Failed to query available provider packages
```

**해결:**

```bash
# Provider 캐시 삭제
rm -rf .terraform
rm -rf .terragrunt-cache

# 재초기화
terragrunt init -upgrade
```

## EKS 클러스터 관련

### kubectl 연결 실패

**증상:**

```text
error: You must be logged in to the server (Unauthorized)
```

**해결:**

```bash
# kubeconfig 갱신
aws eks update-kubeconfig --name <cluster-name> --region ap-northeast-2

# AWS 자격 증명 확인
aws sts get-caller-identity

# IAM 역할 확인
kubectl auth can-i get pods --all-namespaces
```

### Node NotReady 상태

**증상:**

```bash
kubectl get nodes
# NAME            STATUS     ROLES    AGE   VERSION
# node-xxx        NotReady   <none>   1d    v1.28.x
```

**확인 방법:**

```bash
# 노드 상태 확인
kubectl describe node <node-name>

# kubelet 로그 확인 (SSM 또는 SSH)
journalctl -u kubelet -f

# 네트워크 플러그인 확인
kubectl get pods -n kube-system | grep aws-node
```

**일반적인 원인:**

- VPC CNI 플러그인 문제
- Security Group 설정 오류
- 서브넷 IP 고갈

### Pod Pending 상태

**증상:**

```bash
kubectl get pods
# NAME        READY   STATUS    RESTARTS   AGE
# app-xxx     0/1     Pending   0          10m
```

**확인 방법:**

```bash
kubectl describe pod <pod-name>
```

**일반적인 원인 및 해결:**

| 원인 | 해결 |
| ---- | ---- |
| 리소스 부족 | Node Group 스케일 아웃 |
| Node Selector 불일치 | 라벨 확인 및 수정 |
| Taint/Toleration | 적절한 toleration 추가 |
| PVC 바인딩 실패 | StorageClass 및 PV 확인 |

## 네트워크 관련

### Pod 간 통신 실패

**확인:**

```bash
# VPC CNI 상태 확인
kubectl get pods -n kube-system -l k8s-app=aws-node

# ENI 할당 확인
kubectl get node -o jsonpath='{.items[*].status.addresses}'
```

**해결:**

- Security Group 인바운드 규칙 확인
- NACL 규칙 확인
- VPC CNI 버전 업데이트

### ALB Ingress 생성 실패

**증상:**

```text
Failed to create ALB: WebIdentityErr
```

**확인:**

```bash
# ALB Controller 로그
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# IRSA 설정 확인
kubectl describe sa aws-load-balancer-controller -n kube-system
```

**해결:**

- OIDC Provider 생성 확인
- Service Account IAM Role 연결 확인
- 서브넷 태그 확인 (`kubernetes.io/role/elb`)

## 데이터베이스 관련

### RDS 연결 실패

**확인:**

```bash
# Pod에서 연결 테스트
kubectl exec -it <pod-name> -- nc -zv <rds-endpoint> 3306
```

**일반적인 원인:**

- Security Group 미허용
- 서브넷 라우팅 문제
- RDS가 다른 VPC에 있음

### ElastiCache 연결 실패

**확인:**

```bash
# Pod에서 연결 테스트
kubectl exec -it <pod-name> -- redis-cli -h <elasticache-endpoint> ping
```

**해결:**

- Security Group 6379 포트 허용
- 서브넷 그룹 확인

## 모니터링 관련

### CloudWatch 메트릭 미수집

**확인:**

```bash
# CloudWatch Agent 상태
kubectl get pods -n amazon-cloudwatch

# Agent 로그
kubectl logs -n amazon-cloudwatch <agent-pod>
```

**해결:**

- IAM 역할에 CloudWatch 권한 추가
- Agent ConfigMap 확인

## 유용한 디버깅 명령어

```bash
# 클러스터 전체 상태
kubectl get all -A

# 이벤트 확인 (최근 문제 파악)
kubectl get events --sort-by='.lastTimestamp' -A

# 리소스 사용량
kubectl top nodes
kubectl top pods -A

# 특정 네임스페이스 디버깅
kubectl get all,ing,pvc -n <namespace>

# API Server 직접 호출
kubectl get --raw /healthz
```

## 알려진 이슈

이 섹션은 프로젝트에서 발견된 이슈와 해결 방법을 기록합니다.

<!-- 새로운 이슈 발견 시 아래 형식으로 추가:

### 이슈 제목

**발견일:** YYYY-MM-DD
**상태:** 해결됨 / 미해결

**증상:**
설명

**원인:**
설명

**해결:**
설명
-->
