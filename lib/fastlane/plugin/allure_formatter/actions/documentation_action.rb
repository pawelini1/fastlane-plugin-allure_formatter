require 'fastlane/action'
require 'json'
require_relative '../helper/allure_formatter_helper'

module Fastlane
  module Actions
    class DocumentationAction < Action
      def self.run(params)    
        # Input parameters
        testsSourcePath = File.expand_path(params[:testsSourcePath])

        # Implementation
        documentation = Helper::AllureFormatterHelper.generateDocumentation(testsSourcePath: File.expand_path(testsSourcePath))
        if output = params[:output]
          Helper::AllureFormatterHelper.saveJson(data: documentation, savePath: File.expand_path(output))
        end

        return documentation
      end

      def self.description
        "Returns Hash containing all Swift types or functions containing custom (##) parameters in it's documentation."
      end

      def self.authors
        ["Paweł Szymański"]
      end

      def self.return_value
        "Returns Hash containing all Swift types or functions containing custom (##) parameters in it's documentation."
      end

      def self.details
        # Optional:
        "Returns Hash containing all Swift types or functions containing custom (##) parameters in it's documentation."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :testsSourcePath,
                               description: "Path to a directory containing UI/Unit source code files",
                                  optional: true,
                                 is_string: true,
                                      type: String,
                             default_value: "./"),
          FastlaneCore::ConfigItem.new(key: :output,
                               description: "Path to a file where documentation should be saved",
                                  optional: true,
                                 is_string: true,
                                      type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
