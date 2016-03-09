コマンドラインから C# のライブラリリファレンスを引くツールです。

**作りかけの部分が多いです。**

## 動作サンプルイメージ(予定)

- string クラスのメソッド、プロパティ一覧を表示する

```
% csref string
class String
namespace System

--- static methods ---
Concat Format Intern IsInterned IsNullOrEmpty IsNullOrWhiteSpace Join

--- methods ---
Clone Compare CompareTo Contains Copy CopyTo EndsWith Equals GetEnumerator
GetHashCode GetType GetTypeCode IndexOf IndexOfAny Insert IsNormalized
LastIndexOf LastIndexOfAny Normalize PadLeft PadRight Remove Replace Split
StartsWith Substring ToCharArray ToLower ToLowerInvariant ToString ToUpper
ToUpperInvariant Trim TrimEnd TrimStart

--- property ---
Chars Length
```

- string クラスの Remove メソッドの説明を表示する

```
% csref string remove
String.Remove

Signature:
    string (int startIndex)
    string (int startIndex, int count)

startIndex 以降の文字列を取り除いた新しい文字列を返します。


Example:
    csharp> var s = "helloworld";
    csharp> s.Remove(2);
    "he"
    csharp> s
    "helloworld"
    csharp> s.Remove(2, 3);
    "heworld"
```

## requirement

- Ruby
- `gem install nokogiri`

## モチベーション

プログラミングコンテストの問題を C# で書いているときに、List, Dictionary, HashSet クラスをよく利用しますが、メソッド名を忘れることがあり、コマンドラインからサッとリファレンスを引けたらいいなと思い作り始めました。

## 参考にしているツール

- [refe](http://i.loveruby.net/ja/prog/refe.html)

