require 'nokogiri'

# -----
# TODO:大文字小文字は区別しない
#
# $ csref
# => クラス名一覧を表示
#
# $ csref クラス名
# => クラス名のメソッド一覧を表示
#
# $ csref クラス名 メソッド名
# => クラス名のメソッドのシグネチャとサンプルを表示
#
# クラス名、メソッド名は前方一致で検索
# 複数の候補が存在する場合には、その候補の一覧を出力するのみ。
# 完全マッチする項目が一つの場合は、それを出力する(List.Remove, List.RemoveAt での Remove)
#

# find_xxx    : 引数で指定した名前にマッチする対称を集める(大文字小文字区別しない)
# collect_xxx : 対称を全て集める

XML_FILENAME = 'cs.xml'

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
  ns.map {|e| e.attribute('name').value }
end

def find_classes(doc, class_name)
  ns = doc.xpath('//cs/class')

  ret = []
  ns.each {|e|
    name = e.attribute('name').value.downcase
    if name.start_with?(class_name.downcase)
      # puts "FOUND: #{name}"
      ret << e
    end
  }
  ret
end

#def find_interfaces(doc)
#  # interface 一覧を返す
#  ns = doc.xpath('//cs/interface')
#  ns.map {|e| e.attribute('name').value }
#end

def collect_tag(doc, class_name, tag_name)
  doc.xpath("//cs/class[@name='#{class_name}']/#{tag_name}")
end

def collect_properties(doc, class_name)
  collect_tag(doc, class_name, 'property')
end

def collect_methods(doc, class_name)
  collect_tag(doc, class_name, 'method')
end

def collect_static_methods(doc, class_name)
  collect_tag(doc, class_name, 'static-method')
end

def disp_method_content(doc, class_name, method_name)
  # puts "FIND: #{class_name} #{method_name}"

  ns = doc.xpath("//cs/class[@name='#{class_name}']/method[@name='#{method_name}']")
  if ns.size == 0
    # static method を探す
    ns = doc.xpath("//cs/class[@name='#{class_name}']/static-method[@name='#{method_name}']")
  end

  if ns.size == 0
    # 見つからなかった
    puts "見つかりませんでした class_name:#{class_name} method_name:#{method_name}"
    return
  elsif ns.size == 1
    # マッチする項目が一つだけ見つかった
  else
    # 複数の候補が見つかった
    puts "候補が複数見つかりました class_name:#{class_name} method_name:#{method_name}"
    p ns
    raise
  end

  sigs = []
  desc = ""
  example = ""
  ns.children.each {|e|
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

  puts "#{class_name}.#{method_name}"

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

# 文字列のリストを出力するときに、80 カラムで折り返すようにする
# 文字列の途中では改行しない
def format_list(slist)
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
  ret.join("\n")
end

# API
def csref_class(doc, class_name)
  classes = find_classes(doc, class_name)
  case classes.size
  when 0
    puts "NOT FOUND: #{class_name}"
  when 1
    # メソッド一覧を出力する
    kname = classes[0].attribute('name').value
    puts "class #{kname}"
    puts

    s_methods = collect_static_methods(doc, kname)
    if s_methods.size > 0
      puts '--- static methods ---'
      puts format_list(s_methods.map {|e| e.attribute('name').value }.sort)
      puts
    end

    methods = collect_methods(doc, kname)
    if methods.size > 0
      puts '--- methods ---'
      puts format_list(methods.map {|e| e.attribute('name').value }.sort)
      puts
    end

    properties = collect_properties(doc, kname)
    if properties.size > 0
      puts '--- property ---'
      puts format_list(properties.map {|e| e.attribute('name').value }.sort)
      puts
    end
  else
    # 複数の候補が見つかったので、クラス名を出力する
    puts "#{class_name} にマッチする候補が複数みつかりました:"
    puts classes.map {|e| e.attribute('name').value }.join(" ")
  end
end

def csref_method(doc, class_name, method_name)
  classes = find_classes(doc, class_name)
  if classes.size != 1
    if classes.size == 0
      puts "クラス名が見つかりません: #{class_name}"
    else
      puts "#{class_name} にマッチする候補が複数みつかりました:"
      puts classes.map {|e| e.attribute('name').value }.join(" ")
    end
    exit
  end

  # method_name にマッチするメソッド、静的メソッドを集める
  methods = []

  perfect_class_name = classes[0].attribute('name').value # 正式なクラス名
  ['method', 'static-method'].each {|target|
    classes[0].xpath(target).each {|e|
      name = e.attribute('name').value
      if name.downcase.start_with?(method_name.downcase)
        # puts "match method: #{perfect_class_name}.#{name}"
        methods << e
      end
    }
  }

  if methods.size == 0
    puts "クラス #{perfect_class_name} のメソッドが見つかりません: #{method_name}"
  elsif m = methods.find {|e| e.attribute('name').value.downcase == method_name.downcase }
    # 完全マッチしている項目があるならそれを表示
    # そうでなければ項目名のみ表示

    # puts "perfect match #{method_name}"
    perfect_method_name = m.attribute('name').value
    disp_method_content(doc, perfect_class_name, perfect_method_name)
  elsif methods.size == 1 # 候補が一つしかない
    perfect_method_name = methods[0].attribute('name').value
    disp_method_content(doc, perfect_class_name, perfect_method_name)
  else
    puts "クラス #{perfect_class_name} に複数のメソッド候補が見つかりました:"
    puts methods.map {|e| e.attribute('name').value }.join(" ")
  end
end

def main
  doc = parse_xml()

  case ARGV.size
  when 0
    # クラス名一覧を表示する
    # class, interface, alias 一覧
    puts format_list(collect_class_names(doc))

  when 1
    # クラス名のメソッド一覧を表示する
    class_name = ARGV[0]
    csref_class(doc, class_name)

  when 2
    # クラス名.メソッドのシグネチャとサンプルを表示する
    # (class|interface|alias) (field|method|staticmethod)
    class_name = ARGV[0]
    method_name = ARGV[1]

    csref_method(doc, class_name, method_name)
  else
    puts "USAGE"
    puts "$ csref"
    puts "$ csref クラス名"
    puts "$ csref クラス名 メソッド名"
  end
end

def test1
  doc = parse_xml()
  p collect_class_names(doc)

  csref_class(doc, 'Array')
  # csref_method(doc, 'String', 'la')
  csref_method(doc, 'Mat', 'sin')

  puts '----'
  csref_method(doc, 'Mat', 'atan2')

  puts '----'
  csref_method(doc, 'str', 'indexof')
end

if $0 == __FILE__
  main
  # test1
end

