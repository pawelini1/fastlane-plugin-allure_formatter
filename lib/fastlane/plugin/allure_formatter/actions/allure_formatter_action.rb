require 'fastlane/action'
require 'json'
require_relative '../helper/allure_formatter_helper'

module Fastlane
  module Actions
    class AllureFormatterAction < Action
      def self.run(params)   
        # Input parameters
        reportPath = File.expand_path(params[:reportPath])
        pathProvider = params[:pathProvider]
        testModifier = params[:testModifier]
        quiet = params[:quiet]

        # Implementation
        suites = Helper::AllureFormatterHelper.generateSuites(allTests: Helper::AllureFormatterHelper.getAllTests(reportPath: reportPath, pathProvider: pathProvider, testModifier: testModifier, quiet: quiet))
        widgetSuites = Helper::AllureFormatterHelper.generateWidgetSuites(suites: suites)
        Helper::AllureFormatterHelper.saveSuites(reportPath: reportPath, suites: suites)
        Helper::AllureFormatterHelper.saveWidgetSuites(reportPath: reportPath, suites: widgetSuites)
      end

      def self.description
        "Converts regular iOS report into new version with improved formatting."
      end

      def self.authors
        ["Paweł Szymański"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Converts regular iOS report into new version with improved formatting."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :reportPath,
                               description: "Path to Allure report directory",
                                  optional: false,
                                 is_string: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :pathProvider,
                               description: "Lambda defining path for the given test",
                                  optional: true,
                                 is_string: false,
                                      type: Proc,
                             default_value: lambda { |t| nil }),
          FastlaneCore::ConfigItem.new(key: :testModifier,
                               description: "Lambda returning new test data for given test",
                                  optional: true,
                                 is_string: false,
                                      type: Proc,
                             default_value: lambda { |t| t }),          
          FastlaneCore::ConfigItem.new(key: :quiet,
                               description: "Prevents any console output to be displayed",
                                  optional: true,
                                 is_string: false,
                                      type: Boolean,
                             default_value: false)
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
