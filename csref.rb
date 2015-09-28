# vim: tabstop=2 shiftwidth=2 softtabstop=2

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

XML_FILENAME = 'cs.xml'

def get_xml_path(xml_filename)
  dir = File.expand_path(File.dirname(__FILE__))
  File.join(dir, xml_filename)
end

def parse_xml()
  Nokogiri::HTML(File.open(get_xml_path(XML_FILENAME)))
end

def find_classes(doc)
  # class 一覧を返す
  ns = doc.xpath('//cs/class')
  ns.map {|e| e.attribute('name').value }
end

def find_interfaces(doc)
  # interface 一覧を返す
  ns = doc.xpath('//cs/interface')
  ns.map {|e| e.attribute('name').value }
end

def find_url(doc, class_name)
  ns = doc.xpath("//cs/class[@name='#{class_name}']/url")
  ns.map {|e| e.text }.join('')
end

def find_fields(doc, class_name)
  ns = doc.xpath("//cs/class[@name='#{class_name}']/field")

  ret = []
  ns.each {|e|
    a = e.at('name')
    ret << a.text
  }
  ret
end

def find_properties(doc, class_name)
  ns = doc.xpath("//cs/class[@name='#{class_name}']/property")

  ret = []
  ns.each {|e|
    a = e.at('name')
    ret << a.text
  }
  ret
end

def find_methods(doc, class_name)
  ns = doc.xpath("//cs/class[@name='#{class_name}']/method")

  ret = []
  ns.each {|e|
    a = e.at('name')
    ret << a.text
  }
  ret
end

def find_static_methods(doc, class_name)
  ns = doc.xpath("//cs/class[@name='#{class_name}']/static-method")

  ret = []
  ns.each {|e|
    a = e.at('name')
    ret << a.text
  }
  ret
end

def disp_method_content(doc, class_name, method_name)
  # puts "FIND: #{class_name} #{method_name}"

  # 「..」 で親ノードに上る
  ns = doc.xpath("//cs/class[@name='#{class_name}']/method/name[text()='#{method_name}']/..")
  if ns.size == 0
    # static method を探す
    ns = doc.xpath("//cs/class[@name='#{class_name}']/static-method/name[text()='#{method_name}']/..")
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
    # puts "e.name = <#{e.name}>"

    case e.name
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
    s += ' ' if s.length > 0
    s += e
    if s.length >= 80
      ret << s
      s = ''
    end
  }

  ret << s if s.length > 0
  ret.join("\n")
end

def main
  doc = parse_xml()

  case ARGV.size
  when 0
    # クラス名一覧を表示する
    # class, interface, alias 一覧
    puts format_list(find_classes(doc))

  when 1
    # クラス名のメソッド一覧を表示する
    class_name = ARGV[0]

    sm = find_static_methods(doc, class_name)
    if sm.size > 0
      puts '--- static methods ---'
      puts format_list(sm.sort)
      puts
    end

    m = find_methods(doc, class_name)
    if m.size > 0
      puts '--- methos ---'
      puts format_list(m.sort)
      puts
    end

    pr = find_properties(doc, class_name)
    if pr.size > 0
      puts '--- property ---'
      puts format_list(pr.sort)
      puts
    end

  when 2
    # クラス名.メソッドのシグネチャとサンプルを表示する
    # (class|interface|alias) (field|method|staticmethod)
    class_name = ARGV[0]
    method_name = ARGV[1]

    disp_method_content(doc, class_name, method_name)
  else
    puts "usage"
  end
end

def test
#  doc = get_doc()
#  p classes(doc)
  doc = parse_xml()
  puts "\n--- find_classes(doc) ---"
  p find_classes(doc)

  puts "\n--- find_methods(doc, 'Array') ---"
  p find_methods(doc, 'Array')

  puts "\n--- test ---"
  find_method_content(doc, 'String', 'Substring')
end

if $0 == __FILE__
  main
end


