class FlowRegex
  # 正規表現要素の基底クラス
  # 各要素は「位置集合を受け取り、新しい位置集合を返す変換関数」として動作
  class RegexElement
    # 変換関数の実行
    # input_mask: 入力位置集合（BitMask）
    # text: マッチ対象の文字列
    # debug: デバッグ情報を出力するか
    # 戻り値: 出力位置集合（BitMask）
    def apply(input_mask, text, debug: false)
      raise NotImplementedError, "Subclasses must implement apply method"
    end
    
    # デバッグ用の要素名
    def name
      self.class.name.split('::').last
    end
    
    # デバッグ情報の出力
    def debug_info(step_name, input_mask, output_mask)
      puts "#{step_name}:"
      puts "  Input:  #{input_mask.inspect}"
      puts "  Output: #{output_mask.inspect}"
      puts
    end
  end
end
