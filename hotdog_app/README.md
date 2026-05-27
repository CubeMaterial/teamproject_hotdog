## ⚠️ Git 협업 주의사항

- 브랜치는 각자 이름으로 생성하여 작업하고, 본인 브랜치에 `push/pull`합니다.
- 공용 파일을 수정할 때는 Slack 또는 카카오톡으로 사전에 공유한 후 작업합니다.
- 충돌이 발생하면 임의로 다른 사람의 코드를 수정하지 않고, 본인 코드를 먼저 확인 및 되돌린 뒤 충돌 내용을 팀원에게 공유합니다.
- 충돌 해결 후에는 어떤 파일에서 어떤 문제가 있었는지 커밋 메시지나 팀 채팅에 남깁니다.





## Structure 시초 파일구조는 이런식으로 만들려고 합니다.
lib/
├─ main.dart                                        
├─ core/                         # 공통 모듈 (error, network, utils)                                            
├─ features/                                                
│  └─ auth/                                         
│     ├─ presentation/                                      
│     │  ├─ pages/                                          
│     │  └─ widgets/                                        
│     ├─ domain/                                        
│     │  ├─ models/                         
│     │  ├─ repositories/        # 추상 인터페이스                                      
│     │  └─ usecases/                                           
│     └─ data/                                              
│        ├─ datasources/         # API, local DB                                    
│        ├─ models/              # DTOs                                     
│        └─ repositories/        # 구현체                                   
├─ injection_container.dart      # DI 설정 (get-it)                                             
└─ app.dart                      # MaterialApp, route 설정                                          



## API 구조
Flutter 앱          
  -> API 요청만 보냄            

FastAPI 백엔드              
  -> DB 접속            
  -> 라우터 처리            
  -> JSON 응답          

MySQL/RDS           
  -> FastAPI만 직접 접속                
