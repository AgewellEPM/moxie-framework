import XCTest
@testable import SimpleMoxieSwitcher

final class ControlsViewModelTests: XCTestCase {
    var viewModel: ControlsViewModel!
    var mockMQTTService: MockMQTTService!

    override func setUp() {
        super.setUp()
        mockMQTTService = MockMQTTService()
        viewModel = ControlsViewModel(mqttService: mockMQTTService)
    }

    override func tearDown() {
        viewModel = nil
        mockMQTTService = nil
        super.tearDown()
    }

    // MARK: - Volume Tests
    func testSetVolumeSendsCorrectCommand() async {
        // Given
        let expectedVolume = 75

        // When
        await viewModel.setVolume(expectedVolume)

        // Then
        XCTAssertTrue(mockMQTTService.sendCommandCalled)
        XCTAssertEqual(mockMQTTService.lastCommand, "control")
        XCTAssertEqual(mockMQTTService.lastSpeech, "[volume:75]")
    }

    func testToggleMuteSendsCorrectCommand() async {
        // Given
        viewModel.isMuted = false

        // When
        await viewModel.toggleMute(true)

        // Then
        XCTAssertTrue(mockMQTTService.sendCommandCalled)
        XCTAssertEqual(mockMQTTService.lastSpeech, "[mute:true]")
    }

    // MARK: - Camera Tests
    func testToggleCameraEnabledSendsCorrectCommand() async {
        // When
        await viewModel.toggleCamera(enabled: true)

        // Then
        XCTAssertTrue(mockMQTTService.sendCommandCalled)
        XCTAssertEqual(mockMQTTService.lastSpeech, "[camera:true]")
    }

    // MARK: - Movement Tests
    func testMoveForwardSendsCorrectCommand() async {
        // When
        await viewModel.move(.forward)

        // Then
        XCTAssertTrue(mockMQTTService.sendCommandCalled)
        XCTAssertEqual(mockMQTTService.lastSpeech, "[move:forward]")
    }

    func testLookUpSendsCorrectCommand() async {
        // When
        await viewModel.lookAt(.up)

        // Then
        XCTAssertTrue(mockMQTTService.sendCommandCalled)
        XCTAssertEqual(mockMQTTService.lastSpeech, "[look:up]")
    }

    func testSetArmPositionSendsCorrectCommand() async {
        // When
        await viewModel.setArm(.left, position: .up)

        // Then
        XCTAssertTrue(mockMQTTService.sendCommandCalled)
        XCTAssertEqual(mockMQTTService.lastSpeech, "[arm:left:up]")
    }

    // MARK: - Face Emotion Tests
    func testSetFaceEmotionSendsCorrectCommand() async {
        // When
        await viewModel.setFace(.happy)

        // Then
        XCTAssertTrue(mockMQTTService.sendCommandCalled)
        XCTAssertEqual(mockMQTTService.lastSpeech, "[emotion:happy]")
        XCTAssertTrue(viewModel.statusMessage?.contains("Face changed") ?? false)
    }

    // MARK: - Status Message Tests
    func testStatusMessageClearsAfterDelay() async {
        // Given
        viewModel.statusMessage = "Test message"

        // When
        await viewModel.setVolume(50)

        // Wait for status to be set
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNotNil(viewModel.statusMessage)

        // Wait for clear
        try? await Task.sleep(nanoseconds: 2_100_000_000)

        // Should be cleared
        XCTAssertNil(viewModel.statusMessage)
    }
}