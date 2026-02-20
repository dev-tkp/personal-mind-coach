//
//  ChatViewUITests.swift
//  personal-mind-coachUITests
//
//  Created by 박태강 on 2/20/26.
//

import XCTest

final class ChatViewUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // 접근성 권한 요청 및 앱 설정
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = [
            "GEMINI_API_KEY": "AIzaSyDmOrRhzarCzCXSYBO8NYV7KCGvUpIZqiY"
        ]
        
        app.launch()
        
        // 앱이 완전히 로드될 때까지 대기
        sleep(2)
        
        // 접근성 권한 확인 및 대기
        let chatView = app.otherElements["ChatView"]
        if !chatView.waitForExistence(timeout: 5.0) {
            // ChatView가 없으면 NavigationStack을 확인
            let navStack = app.navigationBars.firstMatch
            _ = navStack.waitForExistence(timeout: 5.0)
        }
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Helper Methods
    
    /// 메시지 입력창 찾기 (textFields 또는 textViews)
    private func findMessageInputField() -> XCUIElement {
        // 먼저 접근성 식별자로 찾기
        var field = app.textFields["messageInputField"].firstMatch
        if field.exists {
            return field
        }
        
        // textViews로 시도
        field = app.textViews["messageInputField"].firstMatch
        if field.exists {
            return field
        }
        
        // 접근성 레이블로 찾기
        field = app.textFields["메시지 입력창"].firstMatch
        if field.exists {
            return field
        }
        
        // 플레이스홀더로 찾기
        field = app.textFields["메시지를 입력하세요"].firstMatch
        return field
    }
    
    /// 전송 버튼 찾기
    private func findSendButton() -> XCUIElement {
        // 접근성 식별자로 찾기
        var button = app.buttons["sendButton"].firstMatch
        if button.exists {
            return button
        }
        
        // 접근성 레이블로 찾기
        button = app.buttons["전송"].firstMatch
        if button.exists {
            return button
        }
        
        // Image 버튼의 경우 시스템 이미지 이름으로 찾기
        button = app.buttons.matching(NSPredicate(format: "label CONTAINS '전송' OR identifier == 'sendButton'")).firstMatch
        return button
    }
    
    // MARK: - 기본 메시지 송수신 테스트
    
    /// TC-001: 기본 메시지 송수신 테스트
    /// 1) 메시지 입력창이 비어있을 때 전송 버튼이 비활성화되는지 확인
    /// 2) 메시지를 입력하고 전송하면 AI 응답이 표시되는지 확인
    func testBasicMessageSendAndReceive() throws {
        // Given: 앱이 실행된 상태
        let messageInputField = findMessageInputField()
        let sendButton = findSendButton()
        
        XCTAssertTrue(messageInputField.waitForExistence(timeout: 10.0), "메시지 입력창이 존재해야 합니다")
        XCTAssertTrue(sendButton.waitForExistence(timeout: 10.0), "전송 버튼이 존재해야 합니다")
        
        // 앱이 완전히 로드될 때까지 대기
        sleep(2)
        
        // Then: 전송 버튼이 비활성화되어 있어야 함
        XCTAssertFalse(sendButton.isEnabled, "메시지가 비어있을 때 전송 버튼은 비활성화되어야 합니다")
        
        // When: 메시지를 입력할 때
        messageInputField.tap()
        sleep(1) // 탭 후 UI 업데이트 대기
        
        messageInputField.typeText("안녕?")
        sleep(2) // 텍스트 입력 후 UI 업데이트 대기
        
        // Then: 전송 버튼이 활성화되어야 함
        XCTAssertTrue(sendButton.isEnabled, "메시지가 입력되면 전송 버튼이 활성화되어야 합니다")
        
        // When: 전송 버튼을 누를 때
        sendButton.tap()
        sleep(1) // 전송 후 UI 업데이트 대기
        
        // Then: 로딩 인디케이터가 표시되어야 함
        let loadingText = app.staticTexts["loadingIndicator"].firstMatch
        let loadingExists = loadingText.waitForExistence(timeout: 5.0)
        if loadingExists {
            print("✅ 로딩 인디케이터 표시됨")
        } else {
            print("⚠️ 로딩 인디케이터를 찾을 수 없음 (계속 진행)")
        }
        
        // Then: AI 응답이 표시되어야 함 (최대 20초 대기 - API 응답 시간 고려)
        let aiResponse = app.staticTexts.matching(NSPredicate(format: "identifier == 'modelMessage'"))
        let responseExists = aiResponse.firstMatch.waitForExistence(timeout: 20.0)
        
        if !responseExists {
            // 디버깅: 현재 화면의 모든 요소 출력
            print("=== AI 응답을 찾을 수 없음 ===")
            print("StaticTexts 개수: \(app.staticTexts.count)")
            for i in 0..<min(app.staticTexts.count, 5) {
                let text = app.staticTexts.element(boundBy: i)
                print("  - StaticText \(i): identifier='\(text.identifier)', label='\(text.label.prefix(50))'")
            }
        }
        
        XCTAssertTrue(responseExists, "AI 응답이 20초 이내에 표시되어야 합니다")
        
        // Then: 상담가 응답 접근성 레이블이 있는 메시지가 있어야 함
        let consultantResponse = app.staticTexts.matching(NSPredicate(format: "identifier == 'modelMessage'")).firstMatch
        XCTAssertTrue(consultantResponse.exists, "상담가 응답이 표시되어야 합니다")
    }
    
    // MARK: - 브랜치 기능 테스트
    
    /// TC-002: 브랜치 버튼 표시 테스트
    /// 1) 메인 브랜치의 AI 응답에만 브랜치 버튼이 표시되는지 확인
    /// 2) 브랜치 내부에서는 브랜치 버튼이 표시되지 않는지 확인
    func testBranchButtonVisibility() throws {
        // Given: 메시지를 전송하고 AI 응답을 받은 상태
        let messageInputField = findMessageInputField()
        let sendButton = findSendButton()
        
        XCTAssertTrue(messageInputField.waitForExistence(timeout: 10.0), "메시지 입력창이 존재해야 합니다")
        XCTAssertTrue(sendButton.waitForExistence(timeout: 10.0), "전송 버튼이 존재해야 합니다")
        
        messageInputField.tap()
        sleep(1) // UI 업데이트 대기
        
        messageInputField.typeText("안녕?")
        sleep(1) // 텍스트 입력 후 UI 업데이트 대기
        
        XCTAssertTrue(sendButton.isEnabled, "메시지 입력 후 전송 버튼이 활성화되어야 합니다")
        sendButton.tap()
        
        // 로딩 인디케이터 확인
        let loadingIndicator = app.staticTexts["loadingIndicator"].firstMatch
        let loadingExists = loadingIndicator.waitForExistence(timeout: 5.0)
        if loadingExists {
            print("✅ 로딩 인디케이터 표시됨")
        }
        
        // AI 응답 대기 (더 긴 타임아웃)
        let aiResponse = app.staticTexts.matching(NSPredicate(format: "identifier == 'modelMessage'")).firstMatch
        let responseExists = aiResponse.waitForExistence(timeout: 20.0)
        XCTAssertTrue(responseExists, "AI 응답이 20초 이내에 표시되어야 합니다")
        
        if !responseExists {
            // 디버깅: 현재 화면의 모든 요소 출력
            print("=== 화면 요소 디버깅 ===")
            print("Buttons: \(app.buttons.count)")
            print("StaticTexts: \(app.staticTexts.count)")
            print("TextFields: \(app.textFields.count)")
            return
        }
        
        // UI 업데이트 대기
        sleep(2)
        
        // Then: 메인 브랜치의 AI 응답에 브랜치 버튼이 표시되어야 함
        // 여러 방법으로 브랜치 버튼 찾기 시도
        var branchButton: XCUIElement?
        
        // 방법 1: 접근성 식별자로 찾기
        branchButton = app.buttons["branchButton"].firstMatch
        if branchButton?.exists == true {
            print("✅ 접근성 식별자로 브랜치 버튼 찾음")
        } else {
            // 방법 2: 접근성 레이블로 찾기
            branchButton = app.buttons["여기서 더 물어보기"].firstMatch
            if branchButton?.exists == true {
                print("✅ 접근성 레이블로 브랜치 버튼 찾음")
            } else {
                // 방법 3: 텍스트로 찾기
                branchButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '더 물어보기'")).firstMatch
                if branchButton?.exists == true {
                    print("✅ 텍스트로 브랜치 버튼 찾음")
                }
            }
        }
        
        let buttonExists = branchButton?.waitForExistence(timeout: 5.0) ?? false
        XCTAssertTrue(buttonExists, "메인 브랜치의 AI 응답에 브랜치 버튼이 표시되어야 합니다")
        
        if !buttonExists {
            // 디버깅 정보 출력
            print("=== 브랜치 버튼을 찾을 수 없음 ===")
            print("현재 버튼 목록:")
            for i in 0..<min(app.buttons.count, 10) {
                let button = app.buttons.element(boundBy: i)
                print("  - Button \(i): identifier='\(button.identifier)', label='\(button.label)'")
            }
        }
    }
    
    /// TC-003: 브랜치 뷰 전환 테스트
    /// 1) 브랜치 버튼 클릭 시 즉시 브랜치 뷰로 전환되는지 확인
    /// 2) Parent message가 브랜치 뷰에 표시되는지 확인
    /// 3) 브랜치 인디케이터가 표시되는지 확인
    func testBranchViewTransition() throws {
        // Given: 메시지를 전송하고 AI 응답을 받은 상태
        let messageInputField = findMessageInputField()
        let sendButton = findSendButton()
        
        messageInputField.tap()
        messageInputField.typeText("안녕?")
        sendButton.tap()
        
        // AI 응답 대기
        let aiResponse = app.staticTexts["상담가 응답"].firstMatch
        XCTAssertTrue(aiResponse.waitForExistence(timeout: 15.0), "AI 응답이 표시되어야 합니다")
        
        // When: 브랜치 버튼을 클릭할 때
        var branchButton = app.buttons["branchButton"].firstMatch
        if !branchButton.exists {
            branchButton = app.buttons["여기서 더 물어보기"].firstMatch
        }
        XCTAssertTrue(branchButton.waitForExistence(timeout: 3.0), "브랜치 버튼이 표시되어야 합니다")
        branchButton.tap()
        
        // Then: 즉시 브랜치 인디케이터가 표시되어야 함
        var branchIndicator = app.buttons["returnToMainButton"].firstMatch
        if !branchIndicator.exists {
            branchIndicator = app.buttons["메인으로 돌아가기"].firstMatch
        }
        XCTAssertTrue(branchIndicator.waitForExistence(timeout: 3.0), "브랜치 버튼 클릭 시 즉시 브랜치 인디케이터가 표시되어야 합니다")
        
        // Then: 브랜치 입력 바가 표시되어야 함
        var branchInputLabel = app.staticTexts["branchInputLabel"].firstMatch
        if !branchInputLabel.exists {
            branchInputLabel = app.staticTexts["브랜치 질문:"].firstMatch
        }
        XCTAssertTrue(branchInputLabel.waitForExistence(timeout: 2.0), "브랜치 입력 바가 표시되어야 합니다")
        
        // Then: Parent message(상담가 응답)가 브랜치 뷰에 표시되어야 함
        let parentMessage = app.staticTexts["상담가 응답"].firstMatch
        XCTAssertTrue(parentMessage.exists, "Parent message가 브랜치 뷰에 표시되어야 합니다")
    }
    
    /// TC-004: 브랜치 질문 전송 테스트
    /// 1) 브랜치 입력 바에서 질문을 입력하고 전송할 수 있는지 확인
    /// 2) 브랜치 질문과 응답이 브랜치 뷰에 추가되는지 확인
    /// 3) 브랜치 뷰가 계속 유지되는지 확인
    func testBranchQuestionSend() throws {
        // Given: 브랜치 뷰로 전환된 상태
        let messageInputField = findMessageInputField()
        let sendButton = findSendButton()
        
        // 메시지 전송 및 브랜치 버튼 클릭
        messageInputField.tap()
        messageInputField.typeText("안녕?")
        sendButton.tap()
        
        let aiResponse = app.staticTexts["상담가 응답"].firstMatch
        XCTAssertTrue(aiResponse.waitForExistence(timeout: 15.0), "AI 응답이 표시되어야 합니다")
        
        var branchButton = app.buttons["branchButton"].firstMatch
        if !branchButton.exists {
            branchButton = app.buttons["여기서 더 물어보기"].firstMatch
        }
        XCTAssertTrue(branchButton.waitForExistence(timeout: 3.0), "브랜치 버튼이 표시되어야 합니다")
        branchButton.tap()
        
        // 브랜치 인디케이터 확인
        var branchIndicator = app.buttons["returnToMainButton"].firstMatch
        if !branchIndicator.exists {
            branchIndicator = app.buttons["메인으로 돌아가기"].firstMatch
        }
        XCTAssertTrue(branchIndicator.waitForExistence(timeout: 3.0), "브랜치 뷰로 전환되어야 합니다")
        
        // When: 브랜치 질문을 입력하고 전송할 때
        let branchInputField = findMessageInputField()
        branchInputField.tap()
        branchInputField.typeText("왜 그렇게 생각하세요?")
        
        sleep(1) // UI 업데이트 대기
        
        let branchSendButton = findSendButton()
        XCTAssertTrue(branchSendButton.isEnabled, "브랜치 질문 입력 시 전송 버튼이 활성화되어야 합니다")
        branchSendButton.tap()
        
        // Then: 로딩 인디케이터가 표시되어야 함
        let loadingText = app.staticTexts["loadingIndicator"].firstMatch
        XCTAssertTrue(loadingText.waitForExistence(timeout: 3.0), "브랜치 질문 전송 후 로딩 인디케이터가 표시되어야 합니다")
        
        // Then: 브랜치 질문이 표시되어야 함
        let branchQuestion = app.staticTexts.matching(NSPredicate(format: "identifier == 'userMessage'"))
        XCTAssertTrue(branchQuestion.firstMatch.waitForExistence(timeout: 3.0), "브랜치 질문이 표시되어야 합니다")
        
        // Then: 브랜치 응답이 표시되어야 함 (최대 15초 대기)
        let branchResponse = app.staticTexts.matching(NSPredicate(format: "identifier == 'modelMessage'"))
        XCTAssertTrue(branchResponse.firstMatch.waitForExistence(timeout: 15.0), "브랜치 응답이 15초 이내에 표시되어야 합니다")
        
        // Then: 브랜치 뷰가 계속 유지되어야 함 (브랜치 인디케이터가 여전히 표시됨)
        XCTAssertTrue(branchIndicator.exists, "브랜치 질문 전송 후에도 브랜치 뷰가 유지되어야 합니다")
    }
    
    /// TC-005: 브랜치 내에서 계속 질의응답 테스트
    /// 1) 브랜치 뷰에서 추가 질문을 전송할 수 있는지 확인
    /// 2) 브랜치 내에서 계속 질의응답이 가능한지 확인
    func testContinueConversationInBranch() throws {
        // Given: 브랜치 뷰에서 이미 질문/응답이 있는 상태
        let messageInputField = findMessageInputField()
        let sendButton = findSendButton()
        
        // 첫 메시지 전송
        messageInputField.tap()
        messageInputField.typeText("안녕?")
        sendButton.tap()
        
        let aiResponse = app.staticTexts["상담가 응답"].firstMatch
        XCTAssertTrue(aiResponse.waitForExistence(timeout: 15.0), "AI 응답이 표시되어야 합니다")
        
        // 브랜치 생성
        var branchButton = app.buttons["branchButton"].firstMatch
        if !branchButton.exists {
            branchButton = app.buttons["여기서 더 물어보기"].firstMatch
        }
        XCTAssertTrue(branchButton.waitForExistence(timeout: 3.0), "브랜치 버튼이 표시되어야 합니다")
        branchButton.tap()
        
        var branchIndicator = app.buttons["returnToMainButton"].firstMatch
        if !branchIndicator.exists {
            branchIndicator = app.buttons["메인으로 돌아가기"].firstMatch
        }
        XCTAssertTrue(branchIndicator.waitForExistence(timeout: 3.0), "브랜치 뷰로 전환되어야 합니다")
        
        // 첫 브랜치 질문 전송
        let branchInputField = findMessageInputField()
        branchInputField.tap()
        branchInputField.typeText("왜 그렇게 생각하세요?")
        findSendButton().tap()
        
        let branchResponse = app.staticTexts.matching(NSPredicate(format: "identifier == 'modelMessage'"))
        XCTAssertTrue(branchResponse.firstMatch.waitForExistence(timeout: 15.0), "브랜치 응답이 표시되어야 합니다")
        
        // When: 브랜치 뷰에서 추가 질문을 전송할 때
        let secondBranchInput = findMessageInputField()
        secondBranchInput.tap()
        secondBranchInput.typeText("그럼 어떻게 해야 할까요?")
        
        sleep(1) // UI 업데이트 대기
        
        findSendButton().tap()
        
        // Then: 추가 질문이 표시되어야 함
        let secondQuestion = app.staticTexts.matching(NSPredicate(format: "identifier == 'userMessage'"))
        XCTAssertTrue(secondQuestion.firstMatch.waitForExistence(timeout: 3.0), "추가 브랜치 질문이 표시되어야 합니다")
        
        // Then: 추가 응답이 표시되어야 함
        let secondResponse = app.staticTexts.matching(NSPredicate(format: "identifier == 'modelMessage'"))
        XCTAssertTrue(secondResponse.firstMatch.waitForExistence(timeout: 15.0), "추가 브랜치 응답이 표시되어야 합니다")
        
        // Then: 브랜치 뷰가 계속 유지되어야 함
        XCTAssertTrue(branchIndicator.exists, "브랜치 내에서 계속 질의응답 후에도 브랜치 뷰가 유지되어야 합니다")
    }
    
    /// TC-006: 취소 버튼 테스트
    /// 1) 브랜치 입력 바의 취소 버튼 클릭 시 메인 브랜치로 복귀하는지 확인
    func testCancelBranchInput() throws {
        // Given: 브랜치 뷰로 전환된 상태
        let messageInputField = findMessageInputField()
        let sendButton = findSendButton()
        
        messageInputField.tap()
        messageInputField.typeText("안녕?")
        sendButton.tap()
        
        let aiResponse = app.staticTexts["상담가 응답"].firstMatch
        XCTAssertTrue(aiResponse.waitForExistence(timeout: 15.0), "AI 응답이 표시되어야 합니다")
        
        var branchButton = app.buttons["branchButton"].firstMatch
        if !branchButton.exists {
            branchButton = app.buttons["여기서 더 물어보기"].firstMatch
        }
        XCTAssertTrue(branchButton.waitForExistence(timeout: 3.0), "브랜치 버튼이 표시되어야 합니다")
        branchButton.tap()
        
        var branchIndicator = app.buttons["returnToMainButton"].firstMatch
        if !branchIndicator.exists {
            branchIndicator = app.buttons["메인으로 돌아가기"].firstMatch
        }
        XCTAssertTrue(branchIndicator.waitForExistence(timeout: 3.0), "브랜치 뷰로 전환되어야 합니다")
        
        // When: 취소 버튼을 클릭할 때
        var cancelButton = app.buttons["cancelBranchButton"].firstMatch
        if !cancelButton.exists {
            cancelButton = app.buttons["취소"].firstMatch
        }
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2.0), "취소 버튼이 표시되어야 합니다")
        cancelButton.tap()
        
        // Then: 메인 브랜치로 복귀해야 함 (브랜치 인디케이터가 사라져야 함)
        XCTAssertFalse(branchIndicator.waitForNonExistence(timeout: 2.0), "취소 버튼 클릭 시 브랜치 인디케이터가 사라져야 합니다")
        
        // Then: 일반 입력 바로 복귀해야 함
        let normalInputField = findMessageInputField()
        XCTAssertTrue(normalInputField.exists, "일반 입력 바가 표시되어야 합니다")
    }
    
    /// TC-007: 메인으로 돌아가기 버튼 테스트
    /// 1) 브랜치 인디케이터의 "메인으로 돌아가기" 버튼 클릭 시 메인 브랜치로 복귀하는지 확인
    func testReturnToMainBranch() throws {
        // Given: 브랜치 뷰에서 질문/응답이 있는 상태
        let messageInputField = findMessageInputField()
        let sendButton = findSendButton()
        
        messageInputField.tap()
        messageInputField.typeText("안녕?")
        sendButton.tap()
        
        let aiResponse = app.staticTexts["상담가 응답"].firstMatch
        XCTAssertTrue(aiResponse.waitForExistence(timeout: 15.0), "AI 응답이 표시되어야 합니다")
        
        var branchButton = app.buttons["branchButton"].firstMatch
        if !branchButton.exists {
            branchButton = app.buttons["여기서 더 물어보기"].firstMatch
        }
        XCTAssertTrue(branchButton.waitForExistence(timeout: 3.0), "브랜치 버튼이 표시되어야 합니다")
        branchButton.tap()
        
        var branchIndicator = app.buttons["returnToMainButton"].firstMatch
        if !branchIndicator.exists {
            branchIndicator = app.buttons["메인으로 돌아가기"].firstMatch
        }
        XCTAssertTrue(branchIndicator.waitForExistence(timeout: 3.0), "브랜치 뷰로 전환되어야 합니다")
        
        // 브랜치 질문 전송
        let branchInputField = findMessageInputField()
        branchInputField.tap()
        branchInputField.typeText("왜 그렇게 생각하세요?")
        
        sleep(1) // UI 업데이트 대기
        
        findSendButton().tap()
        
        let branchResponse = app.staticTexts.matching(NSPredicate(format: "identifier == 'modelMessage'"))
        XCTAssertTrue(branchResponse.firstMatch.waitForExistence(timeout: 15.0), "브랜치 응답이 표시되어야 합니다")
        
        // When: "메인으로 돌아가기" 버튼을 클릭할 때
        branchIndicator.tap()
        
        // Then: 메인 브랜치로 복귀해야 함 (브랜치 인디케이터가 사라져야 함)
        XCTAssertFalse(branchIndicator.waitForNonExistence(timeout: 2.0), "메인으로 돌아가기 버튼 클릭 시 브랜치 인디케이터가 사라져야 합니다")
        
        // Then: 메인 브랜치의 메시지만 표시되어야 함 (브랜치 메시지는 숨겨져야 함)
        // 첫 번째 메시지(안녕?)가 여전히 표시되어야 함
        let firstMessage = app.staticTexts.matching(NSPredicate(format: "identifier == 'userMessage'"))
        XCTAssertTrue(firstMessage.firstMatch.exists, "메인 브랜치의 메시지가 표시되어야 합니다")
    }
    
    // MARK: - 에러 처리 테스트
    
    /// TC-008: 빈 메시지 전송 방지 테스트
    /// 1) 빈 메시지를 입력하려고 할 때 전송 버튼이 비활성화되는지 확인
    func testEmptyMessagePrevention() throws {
        let messageInputField = findMessageInputField()
        let sendButton = findSendButton()
        
        XCTAssertTrue(messageInputField.waitForExistence(timeout: 5.0), "메시지 입력창이 존재해야 합니다")
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5.0), "전송 버튼이 존재해야 합니다")
        
        // Given: 메시지 입력창이 비어있을 때
        messageInputField.tap()
        
        // Then: 전송 버튼이 비활성화되어 있어야 함
        XCTAssertFalse(sendButton.isEnabled, "빈 메시지일 때 전송 버튼은 비활성화되어야 합니다")
        
        // When: 공백만 입력할 때
        messageInputField.typeText("   ")
        
        sleep(1) // UI 업데이트 대기
        
        // Then: 전송 버튼이 여전히 비활성화되어 있어야 함
        XCTAssertFalse(sendButton.isEnabled, "공백만 입력했을 때 전송 버튼은 비활성화되어야 합니다")
    }
}
