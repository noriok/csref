require 'nokogiri'
require 'optparse'

XML_FILENAME = 'cs.xml'

def oporder
  table =<<EOS
演算子の優先順位(優先順位の高いものから低いものの順)
基本式:         x.y f(x) a[x] x++ x-- new typeof checked unchecked
単項式:         + - ! ~ ++x --x (T)x
乗法式:         * / %
加法式:         + / %
シフト:         << >>
関係式と型検査: < > <= >= is as
等値式:         == !=
論理 AND:       &
論理 XOR:       ^
論理 OR:        |
条件 AND:       &&
条件 OR:        ||
条件:           ?:
代入:           = *= /= %= += -= <<= >>= &= ^= |=

代入演算子と条件演算子(?:)の結合規則は、右から左。
それ以外のすべての二項演算子の結合規則は、左から右。
EOS

puts table
end

def check(e)
  raise unless e
end

def get_xml_path(xml_filename)
  dir = File.expand_path(File.dirname(__FILE__))
  File.join(dir, xml_filename)
end

def parse_xml()
  Nokogiri::HTML(File.open(get_xml_path(XML_FILENAME)))
end

def collect_class_names(doc)
  # class 一覧を返す
  ns = doc.xpath('//cs/class')
  ns.map {|e| e.attribute('name').value }.sort
end

def collect_struct_names(doc)
  ns = doc.xpath('//cs/struct')
  ns.map {|e| e.attribute('name').value }.sort
end

def find_classes(doc, word)
  ns = doc.xpath('//cs/class')

  ret = []
  ns.each {|e|
    name = e.attribute('name').value.downcase
    if name.start_with?(word.downcase)
      # puts "found: #{name}"
      ret << e
    end
  }
  ret
end

def find_structs(doc, word)
  ns = doc.xpath('//cs/struct')

  ret = []
  ns.each {|e|
    name = e.attribute('name').value.downcase
    if name.start_with?(word.downcase)
      # puts "found: #{name}"
      ret << e
    end
  }
  ret
end

# 文字列のリストを出力するときに、80 カラムで折り返すようにする
# 文字列の途中では改行しない
def display_list(slist)
  ret = []
  s = ''
  slist.each {|e|
    if (s + e).length >= 80
      ret << s
      s = ""
    end
    s += ' ' if s.length > 0
    s += e
  }

  ret << s if s.length > 0
  puts ret.join("\n")
end

# API
def csref_class_or_struct(doc, word)
  classes = find_classes(doc, word) + find_structs(doc, word)
  case classes.size
  when 0
    puts "NOT FOUND: #{word}"
  when 1
    # メソッド一覧を出力する
    parent = classes[0]

    tagname = parent.name # class or struct
    kname = parent.attribute('name').value
    puts "#{tagname} #{kname}"

    # namespace
    if parent.xpath('namespace').size > 0
      x = parent.xpath('namespace')[0].text
      puts "namespace #{x}"
    end

    puts

    s_methods = parent.xpath('static-method')
    if s_methods.size > 0
      puts '--- static methods ---'
      display_list(s_methods.map {|e| e.attribute('name').value }.sort)
      puts
    end

    methods = parent.xpath('method')
    if methods.size > 0
      puts '--- methods ---'
      display_list(methods.map {|e| e.attribute('name').value }.sort)
      puts
    end

    properties = parent.xpath('property')
    if properties.size > 0
      puts '--- property ---'
      display_list(properties.map {|e| e.attribute('name').value }.sort)
      puts
    end
  else
    # 複数の候補が見つかったので、クラス名を出力する
    puts "#{class_name} にマッチする候補が複数みつかりました:"
    puts classes.map {|e| e.attribute('name').value }.join(" ")
  end
end

def display_method(element, parent)
  check(element.name == 'method' || element.name == 'static-method')

  sigs = []
  desc = ""
  example = ""
  element.children.each {|e|
    case e.name # タグ名
    when 'sig'
      # puts "sig=> #{e.text}"
      sigs << e.text

    when 'desc'
      desc = e.text
      ss = e.text.sub(/^( *\n)+/) { '' }.split("\n")
      # p ss
      if ss.size > 0
        # 一行目の先頭空白文字分だけ各行から取り除く(マッチする場合のみ)
        ret = ss[0].scan(/^ +/)
        if ret.size > 0
          desc = ss.map {|e|
            if e.start_with?(ret[0])
              e.slice(ret[0].size, e.length)
            else
              e
            end
          }.join("\n")
        end
      end

    when 'example'
      # puts "example=> #{e.text}"
      example = e.text
    end
  }

  puts "#{parent.attribute("name").value}.#{element.attribute("name").value}"

  puts
  puts "Signature:"
  sigs.each {|sig| puts "    " + sig }

  if desc.length > 0
    puts
    puts desc
  end

  if example.length > 0
    puts
    puts "Example:"
    example.strip.split("\n").each {|line|
      puts "    " + line
    }
  end
end

def display_content(element, parent)
  # puts "#{parent.name} #{parent.attribute("name").value}"
  # puts "element:#{element.name} tag:#{element.attribute("name").value}"

  case element.name
  when "method"
    # puts "method ->"
    display_method(element, parent)

  when "static-method"
    # puts "static method ->"
    display_method(element, parent)
  when "property"
    # puts "property ->"
    puts "プロパティは未実装"
  else
    fail
  end
end

def csref_search(doc, word, subword)
  ms = find_classes(doc, word) + find_structs(doc, word)
  if ms.empty?
    puts "クラス/構造体名が見つかりません: #{word}"
    exit
  elsif ms.size > 1
    puts "#{word} にマッチする候補が複数みつかりました:"
    puts classes.map {|e| e.attribute('name').value }.join(" ")
    exit
  end

  parent = ms[0]
  candidates = []
  perfect_class_name = parent.attribute('name').value # 正式なクラス名
  ['method', 'static-method', 'property'].each {|target|
    parent.xpath(target).each {|e|
      name = e.attribute('name').value
      if name.downcase.start_with?(subword.downcase)
        # puts "match method: #{perfect_class_name}.#{name}"
        candidates << e
      end
    }
  }

  if candidates.empty?
    puts "クラス #{perfect_class_name} のメソッドが見つかりません: #{subword}"
  elsif m = candidates.find {|e| e.attribute('name').value.downcase == subword.downcase }
    # 完全マッチする候補が存在する
    display_content(m, parent)
  elsif candidates.size == 1 # 候補が一つしかない
    display_content(candidates[0], parent)
  else
    puts "複数の候補が見つかりました:"
    puts candidates.map {|e| e.attribute('name').value }.join(" ")
  end
end

def main
  params = ARGV.getopts('o')
  if params['o']
    oporder
    exit
  end

  doc = parse_xml()

  case ARGV.size
  when 0
    # クラス/構造体名一覧を表示する
    xs = collect_class_names(doc) + collect_struct_names(doc)
    display_list(xs.sort)
  when 1
    # クラス/構造体名のメソッド一覧を表示する
    word = ARGV[0]
    csref_class_or_struct(doc, word)
  when 2
    # クラス名.メソッドのシグネチャとサンプルを表示する
    # (class|interface|alias) (field|method|staticmethod)
    word    = ARGV[0]
    subword = ARGV[1]

    csref_search(doc, word, subword)
  else
    puts "USAGE"
    puts "$ csref"
    puts "$ csref クラス名"
    puts "$ csref クラス名 メソッド名"
  end
end

if $0 == __FILE__
  main
end

