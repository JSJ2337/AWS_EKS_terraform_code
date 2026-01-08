# Aurora MySQL Module

Amazon Aurora MySQL 클러스터를 생성하는 모듈입니다.

## 개요

이 모듈은 프로덕션 수준의 Aurora MySQL 클러스터를 생성합니다:

- **Aurora Cluster**: MySQL 호환 클러스터
- **Aurora Instances**: Writer + Reader 인스턴스
- **Secrets Manager**: 자격 증명 자동 관리
- **Parameter Groups**: 최적화된 설정
- **Security Group**: 네트워크 접근 제어
- **Enhanced Monitoring**: 상세 모니터링

## 아키텍처

```text
Aurora MySQL Cluster
├── Cluster
│   ├── Engine: aurora-mysql 8.0
│   ├── Storage: 암호화 (KMS)
│   └── Backup: 자동 백업
│
├── Instances
│   ├── Writer (Primary)
│   └── Reader (Replica)
│
├── Networking
│   ├── DB Subnet Group
│   └── Security Group
│
├── Configuration
│   ├── Cluster Parameter Group
│   └── Instance Parameter Group
│
├── Monitoring
│   ├── Enhanced Monitoring
│   ├── Performance Insights
│   └── CloudWatch Logs
│
└── Security
    └── Secrets Manager (Credentials)
```

## 사용법

```hcl
module "aurora_mysql" {
  source = "../../modules/aurora-mysql"

  cluster_identifier = "my-aurora-cluster"
  engine_version     = "8.0.mysql_aurora.3.08.0"
  database_name      = "mydb"
  master_username    = "admin"

  instance_class = "db.t3.medium"
  instances = {
    writer = {}
    reader = {
      promotion_tier = 2
    }
  }

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.database_subnet_ids

  allowed_security_group_ids = [module.security.eks_pods_security_group_id]

  storage_encrypted = true
  kms_key_id        = module.foundation.kms_key_arn

  backup_retention_period = 7
  deletion_protection     = true

  monitoring_interval           = 60
  performance_insights_enabled  = false  # db.t3는 미지원

  tags = {
    Environment = "prod"
  }
}
```

## 입력 변수

| 변수명 | 설명 | 타입 | 기본값 | 필수 |
|--------|------|------|--------|------|
| `cluster_identifier` | Aurora 클러스터 식별자 | `string` | - | ✅ |
| `engine_version` | Aurora MySQL 엔진 버전 | `string` | `8.0.mysql_aurora.3.05.2` | ❌ |
| `database_name` | 기본 데이터베이스 이름 | `string` | `petclinic` | ❌ |
| `master_username` | 마스터 사용자 이름 | `string` | `admin` | ❌ |
| `master_password` | 마스터 비밀번호 (null이면 자동 생성) | `string` | `null` | ❌ |
| `instance_class` | Aurora 인스턴스 클래스 | `string` | `db.t3.medium` | ❌ |
| `instances` | Aurora 인스턴스 맵 | `map(object)` | Writer + Reader | ❌ |
| `vpc_id` | VPC ID | `string` | - | ✅ |
| `subnet_ids` | Database 서브넷 ID 목록 | `list(string)` | - | ✅ |
| `allowed_security_group_ids` | 접근 허용 보안 그룹 ID | `list(string)` | `[]` | ❌ |
| `allowed_cidr_blocks` | 접근 허용 CIDR 블록 | `list(string)` | `[]` | ❌ |
| `port` | 데이터베이스 포트 | `number` | `3306` | ❌ |
| `backup_retention_period` | 백업 보관 기간 (일) | `number` | `7` | ❌ |
| `storage_encrypted` | 스토리지 암호화 활성화 | `bool` | `true` | ❌ |
| `kms_key_id` | 암호화용 KMS 키 ID | `string` | `null` | ❌ |
| `monitoring_interval` | Enhanced Monitoring 간격 (초) | `number` | `60` | ❌ |
| `performance_insights_enabled` | Performance Insights 활성화 | `bool` | `true` | ❌ |
| `deletion_protection` | 삭제 방지 활성화 | `bool` | `true` | ❌ |
| `skip_final_snapshot` | 최종 스냅샷 생략 | `bool` | `false` | ❌ |
| `apply_immediately` | 즉시 변경 적용 | `bool` | `false` | ❌ |
| `tags` | 공통 태그 | `map(string)` | `{}` | ❌ |

## 출력 값

| 출력명 | 설명 |
|--------|------|
| `cluster_id` | Aurora 클러스터 ID |
| `cluster_arn` | Aurora 클러스터 ARN |
| `cluster_identifier` | Aurora 클러스터 식별자 |
| `cluster_endpoint` | Writer 엔드포인트 |
| `cluster_reader_endpoint` | Reader 엔드포인트 |
| `cluster_port` | 데이터베이스 포트 |
| `database_name` | 데이터베이스 이름 |
| `master_username` | 마스터 사용자 이름 |
| `security_group_id` | Aurora 보안 그룹 ID |
| `subnet_group_name` | 서브넷 그룹 이름 |
| `secret_arn` | Secrets Manager 시크릿 ARN |
| `secret_name` | Secrets Manager 시크릿 이름 |
| `instance_endpoints` | 인스턴스별 엔드포인트 맵 |
| `instance_identifiers` | 인스턴스 식별자 맵 |

## Parameter Groups

### Cluster Parameter Group

| 파라미터 | 값 | 설명 |
|----------|-----|------|
| `character_set_server` | `utf8mb4` | 서버 문자셋 |
| `character_set_client` | `utf8mb4` | 클라이언트 문자셋 |
| `collation_server` | `utf8mb4_unicode_ci` | 정렬 규칙 |
| `time_zone` | `Asia/Seoul` | 타임존 |
| `slow_query_log` | `1` | 슬로우 쿼리 로그 활성화 |
| `long_query_time` | `1` | 슬로우 쿼리 기준 (초) |

### Instance Parameter Group

| 파라미터 | 값 | 설명 |
|----------|-----|------|
| `max_connections` | `1000` | 최대 연결 수 |

## Secrets Manager

자격 증명은 자동으로 Secrets Manager에 저장됩니다:

```json
{
  "username": "admin",
  "password": "auto-generated",
  "host": "cluster-endpoint",
  "port": 3306,
  "database": "petclinic"
}
```

애플리케이션에서 사용:

```python
import boto3
import json

client = boto3.client('secretsmanager')
secret = json.loads(
    client.get_secret_value(SecretId='my-cluster-credentials')['SecretString']
)
```

## 인스턴스 타입 제약사항

| 인스턴스 타입 | Performance Insights | Enhanced Monitoring |
|--------------|---------------------|---------------------|
| db.t3.* | ❌ | ✅ |
| db.r5.* | ✅ | ✅ |
| db.r6g.* | ✅ | ✅ |

## 의존성

- `00-foundation`: KMS 키
- `10-networking`: Database Subnet IDs, VPC ID
- `20-security`: EKS Pods Security Group ID

## 백업 및 복구

- **자동 백업**: `backup_retention_period` 기간 동안 보관
- **백업 윈도우**: `03:00-04:00` (기본)
- **유지보수 윈도우**: `sun:04:00-sun:05:00` (기본)
- **Point-in-Time Recovery**: 지원

## 보안 권장사항

- `allowed_security_group_ids`로 접근 제한
- KMS 암호화 활성화
- `deletion_protection = true` 설정
- 프로덕션에서는 `skip_final_snapshot = false`

## 관련 문서

- [Amazon Aurora User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/)
- [Aurora MySQL Reference](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.AuroraMySQL.html)
- [Aurora Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.BestPractices.html)
