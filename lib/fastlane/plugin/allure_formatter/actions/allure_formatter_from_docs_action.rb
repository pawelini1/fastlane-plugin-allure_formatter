require 'fastlane/action'
require 'json'
require_relative '../helper/allure_formatter_helper'

module Fastlane
  module Actions
    class AllureFormatterFromDocsAction < Action
      def self.run(params)    
        # Input parameters
        reportPath = File.expand_path(params[:reportPath])
        quiet = params[:quiet]

        # Implementation
        allDocs = Helper::AllureFormatterHelper.generateDocumentation(testsSourcePath: File.expand_path(params[:testsSourcePath]))

        allTests = Helper::AllureFormatterHelper.getAllTests(
          reportPath: reportPath, 
          pathProvider: lambda { |test|
            path = test['historyId'].split("/")
            moduleName = path[0]
            testCaseClass = path[1]
            return [
              Helper::AllureFormatterHelper.value(allDocs, "#{testCaseClass}.values.AllureModule") || moduleName,
              Helper::AllureFormatterHelper.value(allDocs, "#{testCaseClass}.values.AllureName") || testCaseClass
            ]
          },
          testModifier: lambda { |test|
            testPath = test['fullName']
            
            if testDescription = Helper::AllureFormatterHelper.value(allDocs, "#{testPath}.values.AllureDescription")
              puts "  > Description: " + "#{testDescription.gsub("\n", "\\n")}".green if !quiet
              test['description'] = testDescription
              test['descriptionHtml'] = testDescription.gsub("\n", "<br>")
            end

            if testName = Helper::AllureFormatterHelper.value(allDocs, "#{testPath}.values.AllureName")
              puts "  > Name: " + "#{testName.gsub("\n", "\\n")}".green if !quiet
              test['name'] = testName
            end

            if testLinks = Helper::AllureFormatterHelper.value(allDocs, "#{testPath}.values.AllureLinks")
              links = testLinks.scan(/\[(\w*-\d*)\]\(([^)]*)\)/).map { |match| { 'name': match[0], 'url': match[1], 'type': 'tms'} }
              puts "  > Links: " + "#{links.map{ |l| l[:name] }}".green if !quiet
              test['links'] = links
            end            
            
            if testTags = Helper::AllureFormatterHelper.value(allDocs, "#{testPath}.values.AllureTags")
              tags = testTags.split(",").map { |e| e.strip }
              puts "  > Tags: " + "#{tags}".gsub("\n", "\\n").green if !quiet
              Helper::AllureFormatterHelper.put(value: tags, path: ['extra', 'tags'], data: test)
            end            

            if testMetadata = Helper::AllureFormatterHelper.value(allDocs, "#{testPath}.values")
              test['metadata'] = testMetadata
            end

            return test
          },
          quiet: quiet
        )

        suites = Helper::AllureFormatterHelper.generateSuites(allTests: allTests)
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
          FastlaneCore::ConfigItem.new(key: :testsSourcePath,
                               description: "Path to a directory containing UI/Unit source code files",
                                  optional: false,
                                 is_string: true,
                                      type: String,
                             default_value: "./"),
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
