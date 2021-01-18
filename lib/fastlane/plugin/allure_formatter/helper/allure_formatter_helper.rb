require 'fastlane_core/ui/ui'
require 'securerandom'
require 'fileutils'
require 'colorize'

module Fastlane
  module Helper
    class AllureFormatterHelper
      # class methods that you define here become available in your action
      # as `Helper::AllureFormatterHelper.your_method`
      #
      def self.getTestCase(reportPath:, id:)
        testCaseFile = File.open "#{reportPath}/data/test-cases/#{id}.json"
        JSON.load testCaseFile
      end

      def self.getSuites(reportPath:)
        suitesFile = File.open "#{reportPath}/data/suites.json"
        JSON.load suitesFile
      end

      def self.saveSuites(reportPath:, suites:)
        Helper::AllureFormatterHelper.saveJson(data: suites, savePath: "#{reportPath}/data/suites.json")
      end

      def self.saveWidgetSuites(reportPath:, suites:)
        Helper::AllureFormatterHelper.saveJson(data: suites, savePath: "#{reportPath}/widgets/suites.json")
      end

      def self.getAllTests(reportPath:, suiteProvider:, quiet:)
        allTests = []
        Helper::AllureFormatterHelper.getSuites(reportPath: reportPath)['children'].each { |suite|
          allTests.push(*suite['children'].map { |test|
            testData = Helper::AllureFormatterHelper.getTestCase(reportPath: reportPath, id: test['uid'])
            suite = suiteProvider.call(testData)
            puts "Putting " + "#{testData['historyId']}".cyan + " into suite: " + "#{suite}".green if !quiet
            test['path'] = [suite, testData['name']]
            test
          })
        }
        allTests
      end

      def self.generateSuites(allTests:)
        suites = {}
        allTests.each { |test|
          Helper::AllureFormatterHelper.put(
            value: test,
            path: test['path'], 
            data: suites
          )
        }
        Helper::AllureFormatterHelper.generateChildren(suites: suites)
      end

      def self.generateWidgetSuites(suites:)
        {
          'total': suites[:children].count(),
          'items': suites[:children].map { |suite|
            stats = suite[:children].inject(Hash.new(0)) { |stats, test| stats[test['status']] += 1; stats}
            {
              'uid': suite[:uid],
              'name': suite[:name],
              'statistic': {
                'failed': stats['failed'],
                'broken': stats['broken'],
                'skipped': stats['skipped'],
                'passed': stats['passed'],
                'unknown': stats['unknown'],
                'total': suite[:children].count()
              }
            }
          }
        }
      end

      def self.generateChildren(suites:)
        {
          'uid': SecureRandom.uuid,
          'name': 'suites',
          'children': suites.map { |key, value|
            uuid = SecureRandom.uuid
            {
              'uid': uuid,
              'name': key,
              'children': value.map { |name, test|
                test['parentUid'] = uuid
                test
              }
            }
          }
        }
      end

      def self.put(data:, path:, value:)
        if path.length == 1
          data[path.first] = value
          return
        end

        key = path.first()
        if data[key] == nil
          data[key] = {}
        end
        
        put(
          value: value,
          path: path[1..-1], 
          data: data[key]
        )
      end
      
      def self.saveJson(data:, savePath:)
        FileUtils.mkdir_p File.expand_path File.dirname savePath
        File.open(savePath, "w") do |f|
          f.write(JSON.pretty_generate(data))
        end
      end      
    end
  end
end
