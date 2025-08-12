# 📄 AWS EC2 + CodeDeploy + CodePipeline 배포 과정 정리 (초안)

배포(cloudfront): https://d14raflbqhfvlk.cloudfront.net/

## 1. 개요
목표: GitHub에 push한 코드를 자동으로 AWS EC2 인스턴스에 배포

사용 서비스:

- Amazon EC2: 애플리케이션이 동작할 서버
- AWS CodeDeploy: EC2에 코드를 배포하고 배포 스크립트를 실행
- AWS CodePipeline: 소스 변경 감지 → 빌드/배포 자동화
- PM2: Node.js 애플리케이션 프로세스 관리

## 2. 인프라 구성도

```
[GitHub] 
   ↓ (push/merge)
[CodePipeline] ──→ [CodeDeploy] ──→ [EC2 Instance]
```

- GitHub에서 특정 브랜치에 코드 변경이 발생하면 CodePipeline이 트리거
- CodeDeploy가 EC2의 CodeDeploy Agent를 통해 애플리케이션 업데이트

## 3. 사전 준비
EC2 인스턴스 생성

- Ubuntu 24.04 LTS
- 보안그룹에 HTTP(80), SSH(22), 애플리케이션 포트(예: 3000) 열기
- IAM Role: AmazonEC2RoleforAWSCodeDeploy 또는 AmazonEC2FullAccess + S3 권한

CodeDeploy Agent 설치

```bash
sudo apt update
sudo apt install ruby-full wget
wget https://aws-codedeploy-<region>.s3.<region>.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent start
Node.js / PM2 설치
```

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs build-essential
sudo npm install -g pm2
pm2 startup systemd
```
## 4. 애플리케이션 준비

appspec.yml (배포 구성 파일)

```yml
version: 0.0
os: linux
hooks:
  ApplicationStart:
    - location: deploy.sh
      timeout: 600
      runas: ubuntu
```
deploy.sh (배포 스크립트)

```bash
#!/bin/bash
cd /home/ubuntu/aws-EC2-practice
git pull origin main
sudo npm install
sudo npm run build
pm2 describe next_app >/dev/null 2>&1 && pm2 restart next_app || pm2 start "npm start" --name next_app
```
실행 권한 부여
```bash
chmod +x deploy.sh
git add appspec.yml deploy.sh
git commit -m "Add deployment files"
git push origin main
```
### 5. CodeDeploy 설정
Application 생성
- Compute platform: EC2/On-premises
Deployment Group 생성

- 대상: 태그 기반 인스턴스 선택
- 서비스 역할: CodeDeployRole (S3, EC2 권한 포함)
- 배포 구성: CodeDeployDefault.OneAtATime (테스트 단계)

## 6. CodePipeline 설정
Source 단계

- Provider: GitHub
- 연결: GitHub Access Token
- 브랜치: main

Build 단계

- (없음) 또는 CodeBuild에서 테스트/빌드 가능

Deploy 단계

- Provider: CodeDeploy
- Application & Deployment Group 선택

## 7. 동작 흐름

CodePipeline - Source 단계

- GitHub(또는 CodeCommit)에서 main 브랜치 변경 감지
- 변경된 코드 ZIP 형태로 S3 버킷에 저장 (CodePipeline 내부에서 쓰는 Artifact S3 버킷)

CodePipeline - Deploy 단계

- CodeDeploy에 “이 S3 아티팩트를 EC2에 배포하라” 명령 전달
- 이때 CodePipeline이 S3 버킷 경로와 파일 정보를 CodeDeploy에 넘김

CodeDeploy - EC2 배포 실행

- EC2에 설치된 CodeDeploy Agent가 S3에서 해당 ZIP 다운로드
- /opt/codedeploy-agent/deployment-root/... 임시 경로에 압축 해제
- appspec.yml에 정의된 훅(deploy.sh) 순서대로 실행

EC2 - 빌드 & 실행
- deploy.sh에서 npm install && npm run build 실행
- 빌드 결과를 PM2로 실행/재시작


## 8. 트러블슈팅 메모
PM2 프로세스 없음 에러 → deploy.sh에서 pm2 describe 조건 추가

홈 디렉터리에 package-lock.json 생김 → cd 경로 확인 삭제 후 redeploy

SSH 접속 불가 → AWS 콘솔에서 재부팅 또는 Stop/Start로 리소스 초기화

