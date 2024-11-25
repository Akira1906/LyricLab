# frozen_string_literal: true

module LyricLab
  module OpenAI
    # line credit calculation methods
    class GptWordProcessor
      def initialize(openai)
        # do something
        @openai = openai
      end

      def extract_words(text) # rubocop:disable Metrics/MethodLength
        # should return a list of unique words extracted by ChatGPT
        extract_message = [
          { role: 'system', content: '你是一個專業的繁體中文老師，可以從文本中提取有意義的繁體中文詞彙單位' },
          { role: 'user', content: "Extract every single unique traditional chinese word from the following text:
        reply in this format (one word per line):
        你好
        風
        雲
        天空

        #{text}" }
        ]

        response = @openai.chat_response(extract_message)
        response.split("\n")

        response.split("\n")
          .map(&:strip)
          .reject(&:empty?)
          .uniq

        # puts "Extracted words:"
        # puts words
      end

      def extract_separated_text(text)
        # should return a list of unique words extracted by ChatGPT
        extract_message = [
          { role: 'system', content: '你是一個專業的繁體中文老師，可以從文本中提取有意義的繁體中文詞彙單位，務必確認文本中的每一個字都有被歸在一個詞彙單位' },
          { role: 'user', content: "Separate all the words in the following text from each other and:
        reply in this format (words separated by spaces):
        你好 風 雲 天空 I am cool

        #{text}" }
        ]

        @openai.chat_response(extract_message)
      end

      def get_words_metadata(input_words) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
        message = [
          { role: 'system', content: '現在你是一名繁體中文老師，要指導外國人學習中文，分析以下文字`,每個difficulty至少有兩個詞彙並確保一樣的文字是一樣的difficulty分級，至少標註30個詞彙：' },
          { role: 'user', content: "Please identify these words and respond in this format:
            Word:[繁體中文字]
            translate:[English translation ONLY]
            Pinyin:[標註聲調的拼音]
            Difficulty:[select one of those：beginner、novice1、novice2、level1、level2、level3、level4, level5]
            Definition:[English detailed translation ONLY]
            Word type:[選擇詞性：N,V,Adj,Adv,Pron,Prep,Conj,Num,Int,Classifier,Idiom,Other]
            Example:[實用的20字內繁體中文例句]

            確保文本中的每一個詞彙都有被解析到.

            Words: #{input_words}" }
        ]

        begin
          # response = @openai.chat_response(message)
          # puts "Raw response from ChatGPT:"
          # puts response
          response = @openai.chat_response(message)
          words = []
          current_word = {}

          response.split("\n").each do |line|
            line = line.strip
            case line
            when /^Word:\s*(.+)/
              words << current_word if current_word[:characters]
              current_word = { characters: ::Regexp.last_match(1) }
            when /^Translate:\s*(.+)/
              current_word[:english] = ::Regexp.last_match(1)
              current_word[:translation] = ::Regexp.last_match(1) || 'unknown'
            when /^Pinyin:\s*(.+)/
              current_word[:pinyin] = ::Regexp.last_match(1) || 'unknown'
            when /^Difficulty:\s*(.+)/
              current_word[:language_level] = ::Regexp.last_match(1) || 'unknown'
            when /^Definition:\s*(.+)/
              current_word[:definition] = ::Regexp.last_match(1) || 'unknown'
              # current_word[:translation] = combine_definitions(current_word[:english], ::Regexp.last_match(1))
            when /^Word type:\s*(.+)/
              current_word[:word_type] = ::Regexp.last_match(1) || 'unknown'
            when /^Example:\s*(.+)/
              current_word[:example_sentence] = ::Regexp.last_match(1) || 'No example provided'
            end
          end

          # Add the last word
          words << current_word if current_word[:characters]
          
          # check every word has all the required fields for default
          words.map do |word|
            word[:translation] ||= 'unknown'
            word[:pinyin] ||= 'unknown'
            word[:language_level] ||= 'unknown'
            word[:definition] ||= 'unknown'
            word[:word_type] ||= 'unknown'
            word[:example_sentence] ||= 'No example provided'
            word
          end
        end
        words
      end

      def create_word_entity(word_data)
        Entity::Word.new(
          id: nil,
          characters: word_data[:characters],
          pinyin: word_data[:pinyin] || 'unknown',
          translation: word_data[:translation] || 'unknown',
          example_sentence: word_data[:example_sentence] || 'No example provided',
          language_level: word_data[:language_level] || 'unknown',
          definition: word_data[:definition] || 'No definition provided',
          word_type: word_data[:word_type] || 'unknown'
        )
      end

      # def combine_definitions(english, chinese)
      #   parts = []
      #   parts << english if english
      #   parts << chinese if chinese
      #   parts.join(' | ')
      # end
    end
  end
end
