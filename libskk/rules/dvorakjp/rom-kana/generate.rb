#!/usr/bin/env ruby
require 'json'

vowelToKana = {'a' => 'あ', 'i' => 'い', 'u' => 'う', 'e' => 'え', 'o' => 'お'}

consonantVowelToKana = {
  'c'  => {'a' => 'か',   'i' => 'き',   'u' => 'く',    'e' => 'け',   'o' => 'こ'},
  'g'  => {'a' => 'が',   'i' => 'ぎ',   'u' => 'ぐ',    'e' => 'げ',   'o' => 'ご'},
  's'  => {'a' => 'さ',   'i' => 'し',   'u' => 'す',    'e' => 'せ',   'o' => 'そ'},
  'z'  => {'a' => 'ざ',   'i' => 'じ',   'u' => 'ず',    'e' => 'ぜ',   'o' => 'ぞ'},
  't'  => {'a' => 'た',   'i' => 'ち',   'u' => 'つ',    'e' => 'て',   'o' => 'と'},
  'd'  => {'a' => 'だ',   'i' => 'ぢ',   'u' => 'づ',    'e' => 'で',   'o' => 'ど'},
  'n'  => {'a' => 'な',   'i' => 'に',   'u' => 'ぬ',    'e' => 'ね',   'o' => 'の'},
  'h'  => {'a' => 'は',   'i' => 'ひ',   'u' => 'ふ',    'e' => 'へ',   'o' => 'ほ'},
  'b'  => {'a' => 'ば',   'i' => 'び',   'u' => 'ぶ',    'e' => 'べ',   'o' => 'ぼ'},
  'p'  => {'a' => 'ぱ',   'i' => 'ぴ',   'u' => 'ぷ',    'e' => 'ぺ',   'o' => 'ぽ'},
  'f'  => {'a' => 'ふぁ', 'i' => 'ふぃ', 'u' => 'ふ',    'e' => 'ふぇ', 'o' => 'ふぉ'},
  'm'  => {'a' => 'ま',   'i' => 'み',   'u' => 'む',    'e' => 'め',   'o' => 'も'},
  'y'  => {'a' => 'や',   'i' => 'いぃ', 'u' => 'ゆ',    'e' => 'いぇ', 'o' => 'よ'},
  'r'  => {'a' => 'ら',   'i' => 'り',   'u' => 'る',    'e' => 'れ',   'o' => 'ろ'},
  'w'  => {'a' => 'わ',   'i' => 'うぃ', 'u' => 'うぅ',  'e' => 'うぇ', 'o' => 'を'},
  'v'  => {'a' => 'ゔぁ', 'i' => 'ゔぃ', 'u' => 'ゔ',    'e' => 'ゔぇ', 'o' => 'ゔぉ'},
  'wh' => {'i' => 'ゐ',   'e' => 'ゑ',   'o' => 'うぉ'},
  'ts' => {'u' => 'つ'},
  'fn' => {'u' => 'ふゅ'},
  'vh' => {'u' => 'ゔゅ'},
}

consonantToYoonConsonant = {
  'c' => 'n',
  'g' => 'n',
  's' => 'h',
  'z' => 'h',
  't' => 'n',
  'd' => 'n',
  'n' => 'h',
  'h' => 'n',
  'b' => 'n',
  'p' => 'n',
  'm' => 'n',
  'r' => 'h',
}

vowelToYoonKana = {
  'a' => 'ゃ',
  'i' => 'ぃ',
  'u' => 'ゅ',
  'e' => 'ぇ',
  'o' => 'ょ',
}

difthongs = [
  [':', 'a', 'i'],
  [',', 'o', 'u'],
  ['.', 'e', 'i'],
]

expantionOfN = {
  'a' => ';',
  'i' => 'x',
  'u' => 'k',
  'e' => 'j',
  'o' => 'q',
}

romajiToKana = {}

vowelToKana.each do |vowel, kana|
  romajiToKana[vowel] = ['', kana]
end

consonantVowelToKana.each do |consonant, kanas|
  yoonConsonant = consonantToYoonConsonant[consonant]

  if consonant.size == 1 then
    if consonant == 'n' then
      romajiToKana[consonant * 2] = ['', 'ん']
    else
      romajiToKana[consonant * 2] = [consonant, 'っ']
    end
  end

  kanas.each do |vowel, kana|
    romajiToKana[consonant + vowel] = ['', kana]
    romajiToKana[consonant + expantionOfN[vowel]] = ['', kana + 'ん']

    if yoonConsonant then
      romajiToKana[consonant + yoonConsonant + vowel] = ['', kanas['i'] + vowelToYoonKana[vowel]]
      romajiToKana[consonant + yoonConsonant + expantionOfN[vowel]] = ['', kanas['i'] + vowelToYoonKana[vowel]  + 'ん']
    end
  end

  difthongs.map do |key, firstVowel, secondVowel|
    if kanas[firstVowel] then
      romajiToKana[consonant + key] = ['', kanas[firstVowel] + vowelToKana[secondVowel]] 
      romajiToKana[consonant + yoonConsonant + key] = ['', kanas['i'] + vowelToYoonKana[firstVowel] + vowelToKana[secondVowel]] if yoonConsonant
    end
  end
end

romajiToKana.merge!({
  'thi':  ['', 'てぃ'],
  'dhi':  ['', 'でぃ'],
  'xx':   ['x', 'っ'],
  'xa':   ['', 'ぁ'],
  'xe':   ['', 'ぇ'],
  'xi':   ['', 'ぃ'],
  'xca':  ['', 'か', 'ヵ'],
  'xce':  ['', 'け', 'ヶ'],
  'xo':   ['', 'ぉ'],
  'xtsu': ['', 'っ'],
  'xtu':  ['', 'っ'],
  'xu':   ['', 'ぅ'],
  'xwa':  ['', 'ゎ'],
  'xya':  ['', 'ゃ'],
  'xyo':  ['', 'ょ'],
  'xyu':  ['', 'ゅ'],
  'hta':  ['', '🙂'],
  'hto':  ['', '👌'],
  'hti':  ['', '👍'],
  '-':    ['', 'ー'],
  ':':    ['', '：'],
  ';':    ['', '；'],
  '?':    ['', '？'],
  '!':    ['', '！'],
  '[':    ['', '「'],
  ']':    ['', '」'],
  '~':    ['', '〜'],
  '/':    ['', '・'],
  '(':    ['', '（'],
  ')':    ['', '）'],
})


puts JSON.pretty_generate({
  define: {
    'rom-kana' => romajiToKana
  }
})
