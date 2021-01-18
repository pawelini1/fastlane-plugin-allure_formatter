describe Fastlane::Actions::AllureFormatterAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The allure_formatter plugin is working!")

      Fastlane::Actions::AllureFormatterAction.run(nil)
    end
  end
end
