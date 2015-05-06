# vim: tabstop=2 shiftwidth=2 softtabstop=2

require 'nokogiri'

# csref -- コマンドラインから参照する C# 簡易リファレンス ---
# 『Unixプログラミング環境』に書いてあったことを思い出す(mm にメモしておこう)
#
# - まず役に立つもっともシンプルなもの作る
# - つぎに必要になるものを足していく
# 
# - クラス一覧を知りたい。
#   C++ の map に相当するものは C# ではどれ？
#
# - そのクラスで定義されている field, property, method, staticmethod を知りたい
#   使い方:
#   $ csref List
# 
#   [必要ないかも]
# - そのクラスのメソッド一覧が知りたい
#   List に要素を追加するのは Add だっけ？それとも Append だろうか
#   (使い方が難しいものに関しては、サンプルコードも欲しい)
#   使い方:
#   $ csref List# # クラス名の後ろに「#」をつけるとメソッド一覧
#
# - メソッドの詳しい情報がしりたい
#   - 引数
#   - 戻り値
#   - サンプル
#   使い方:
#   $ csref List Add # List の Add をリファレンスを表示する(field, property, method, staticmethod区別しない)
#     - 前方一致とか必要だろうか
#   
#
# - 検索関連
# 

class Ref < Struct.new(:classname, 
                       :constructor,
                       :fields,
                       :properties,
                       :methods,
                       :staticmethods,
                       :url # MSDN
                      )
end

def parse(xml_filename)
  doc = Nokogiri::HTML(File.open(xml_filename))
  
  refs = []  
  classes(doc).each {|classname|
    ref = Ref.new(classname,
                  [],
                  fields(doc, classname),
                  properties(doc, classname),
                  methods(doc, classname),
                  staticmethods(doc, classname),
                  url(doc, classname)
                 )
    refs << ref
  }

  interfaces(doc).each {|interfacename|
    p interfacename
  }
  
  aliases = []
  return [refs, aliases]
end

def classes(doc)
  # class 一覧を返す
  ns = doc.xpath('//cs/class')
  ns.map {|e| e.attribute('name').value }
end

def interfaces(doc)
  # interface 一覧を返す
  ns = doc.xpath('//cs/interface')
  ns.map {|e| e.attribute('name').value }  
end

def url(doc, class_name)
  ns = doc.xpath("//cs/class[@name='#{class_name}']/url")
  ns.map {|e| e.text }.join('')
end

def fields(doc, class_name)
  ns = doc.xpath("//cs/class[@name='#{class_name}']/field")
  ret = []
  ns.each {|e|
    a = e.at('name')
    ret << a.text
  }
  ret
end

def properties(doc, class_name)
  ns = doc.xpath("//cs/class[@name='#{class_name}']/property")
  ret = []
  ns.each {|e|
    a = e.at('name')
    ret << a.text
  }
  ret
end

def methods(doc, class_name)
  ns = doc.xpath("//cs/class[@name='#{class_name}']/method")

  ret = []
  ns.each {|e|
    a = e.at('name')
    ret << a.text
  }
  ret
end

def staticmethods(doc, class_name)
  ns = doc.xpath("//cs/class[@name='#{class_name}']/staticmethod")

  ret = []
  ns.each {|e|
    a = e.at('name')
    ret << a.text
  }
  ret
end

def open_official_site(url)
  system("open #{url}")
end

def get_doc()
  Nokogiri::HTML(File.open('cs.xml'))
end

def test
  doc = get_doc()
  p classes(doc) 
end

def test_info(class_name)
  doc = get_doc()
  ns = doc.xpath("//cs/class[@name='#{class_name}']")
  if ns.size == 0
    puts "not found: '#{class_name}'"
    exit
  end

  puts "--- fields ---"
  puts fields(doc, class_name).join(', ')
  puts "--- properties ---"
  puts properties(doc, class_name).join(', ')
  puts "--- methods ---"
  puts methods(doc, class_name).join(', ')
  puts "--- staticmethods ---"
  puts staticmethods(doc, class_name).join(', ')
end

def info_classes
  classes(get_doc)  
end

def test_main
  refs, aliases = parse('cs.xml')

  

  case ARGV.size
  when 0
    # class, interface, alias 一覧
    puts info_classes().join(', ')
  when 1
    # (class|interface|alias)
    class_name = ARGV[0]
    # test_info(class_name)

    puts "----- methods -----"
    puts refs.find {|e| e.classname == class_name }.methods.join(', ')
    puts "----- static methods -----"
    puts refs.find {|e| e.classname == class_name }.staticmethods.join(', ')
  when 2
    # (class|interface|alias) (field|method|staticmethod)
    class_name = ARGV[0]
    word = ARGV[1]
    test_info_anything(class_name, word)
  else
    puts "usage"
  end
end

def test_refs
  refs, aliases = parse('cs.xml')

  ref = refs.find {|e| e.classname == 'List' }

  puts ref.classname
  puts ref.methods

  # doc = get_doc
end

def main
  # test_open_official()

  # test_info('Math')

  # test_main
  
  # parse('cs.xml')

  # test_refs
  
  test_main
end


if $0 == __FILE__
  main
end

