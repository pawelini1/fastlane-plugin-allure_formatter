require 'fastlane_core/ui/ui'
require 'securerandom'
require 'fileutils'
require 'colorize'

module Fastlane
  module Helper
    class AllureFormatterHelper
      # Getting all tests from suite and applying new formatting
      def self.getAllTests(reportPath:, pathProvider:, testModifier:, quiet:)
        allTests = []
        Helper::AllureFormatterHelper.getSuites(reportPath: reportPath)['children'].each { |suite|
          allTests.push(*suite['children'].map { |test|
            testData = Helper::AllureFormatterHelper.getTestCase(reportPath: reportPath, id: test['uid'])
            
            puts "Test: " + "#{testData['historyId']}".cyan  if !quiet
            
            testData = testModifier.call(testData)
            saveTestCase(data: testData, reportPath: reportPath)

            path = pathProvider.call(testData) || suite['name']
            
            puts "  > Path: " + "#{path}".green if !quiet
            test['path'] = (path.kind_of?(Array) ? path : [path]) + [testData['name']]

            if test['name'] != testData['name']
              puts "  > Name: " + "#{testData['name']}".green if !quiet
              test['name'] = testData['name']
            end

            test['isTest'] = true
            test
          })
        }
        allTests
      end

      # Generating new suites structure based on updated test testData
      def self.generateSuites(allTests:)
        suites = {}
        allTests.each { |test|
          Helper::AllureFormatterHelper.put(
            value: test,
            path: test['path'], 
            data: suites
          )
        }
        uuid = SecureRandom.uuid
        {
          'uid': uuid,
          'name': 'suites',
          'children': Helper::AllureFormatterHelper.generateSuiteChildren(suites: suites, parent: uuid)
        }
      end

      # Generating suites substructure for given suite
      def self.generateSuiteChildren(suites:, parent:)
        suites.keys.map { |key|
          value = suites[key]
          if value['isTest']
            value['parentUid'] = parent; value
          else
            uuid = SecureRandom.uuid
            {
              'uid': uuid,
              'name': key,
              'children': Helper::AllureFormatterHelper.generateSuiteChildren(suites: value, parent: uuid)
            }
          end
        }
      end

      def self.generateWidgetSuites(suites:)
        {
          'total': suites[:children].count(),
          'items': suites[:children].map { |suite|
            Helper::AllureFormatterHelper.generateWidgetSuiteStats(suite: suite)
          }.flatten
        }
      end

      def self.generateWidgetSuiteStats(suite:, prefix: "")
        stats = suite[:children].inject(Hash.new(0)) { |stats, test| stats[test['status']] += 1 if test['isTest']; stats}
        if stats.empty?
          return suite[:children].map { |subSuite|
            Helper::AllureFormatterHelper.generateWidgetSuiteStats(suite: subSuite, prefix: prefix + suite[:name] + " ❯ ")
          }.flatten
        else
          return [{
            'uid': suite[:uid],
            'name': prefix + suite[:name],
            'statistic': {
              'failed': stats['failed'],
              'broken': stats['broken'],
              'skipped': stats['skipped'],
              'passed': stats['passed'],
              'unknown': stats['unknown'],
              'total': suite[:children].count()
            }
          }]
        end
      end    

      def self.generateDocumentation(testsSourcePath:)    
        regex = "^\\s*##\\s+(\\w+)\\s*\\n\\s*(.*)\\s*$"    
        paths = `pcregrep -Mlr -e '#{regex}' #{testsSourcePath}`.split("\n")
        documentation = paths.map { |path|
          Helper::AllureFormatterHelper.searchSwiftStructure(
            structure: JSON.parse(`sourcekitten doc --single-file #{path}`)[path]['key.substructure'],
            match: lambda { |element| !element['key.doc.comment'].to_s.scan(/#{regex}/).empty? }
          ).map { |element| Documentation.new(element['key.name'], element['key.path'], element['key.doc.comment']) }
        }.flatten.inject(Hash.new(0)) { |hash, element| 
          element.values = element.doc.scan(/#{regex}/).inject(Hash.new(0)) { |hash, matches| 
            hash[matches[0]] = matches[1]
            hash
          }
          hash[(element.path + [element.name]).join("/")] = element.to_hash
          hash
        }
        documentation
      end

      def self.searchSwiftStructure(structure:, match:, path: [])
        if structure == nil
          return []
        end

        matches = []
        structure.each { |element|
          if match.call(element)
            element['key.path'] = path
            matches.push(element)
          end
          matches.push(*searchSwiftStructure(
            structure: element['key.substructure'], 
            match: match,
            path: path + [element['key.name']]))
        }
        matches
      end     

      def self.getTestCase(reportPath:, id:)
        testCaseFile = File.open "#{reportPath}/data/test-cases/#{id}.json"
        JSON.load testCaseFile
      end

      def self.saveTestCase(data:, reportPath:)
        Helper::AllureFormatterHelper.saveJson(data: data, savePath: "#{reportPath}/data/test-cases/#{data['uid']}.json")
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

      def self.value(hash, keypath = "")
        value = hash
        for key in keypath.split('.')
          if value.keys.include? key
            value = value[key]
          else
            return nil
          end
        end
        return value
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

      # Classes
      class Documentation
        def initialize(name, path, doc)
          @name = name
          @path = path
          @doc = doc
          @values = []
        end

        def to_hash
          {'name' => @name, 'path' => @path, 'doc' => @doc, 'values' => @values}
        end

        attr_accessor :name
        attr_accessor :path
        attr_accessor :doc
        attr_accessor :values
      end

    end
  end
end
