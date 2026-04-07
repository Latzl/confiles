# Chinese Punctuation Rule

## Rule

When generating content that contains Chinese text, **all punctuation must use English half-width (ASCII) characters**. Do NOT use full-width punctuation.

## Full-Width vs Half-Width Reference

| Full-Width (Forbidden) | Half-Width (Required) |
|------------------------|-----------------------|
| ，                     | ,                     |
| 。                     | .                     |
| ！                     | !                     |
| ？                     | ?                     |
| ；                     | ;                     |
| ：                     | :                     |
| “                      | "                     |
| ‘                      | '                     |
| ”                      | "                     |
| ’                      | '                     |
| （                     | (                     |
| ）                     | )                     |
| 【                     | [                     |
| 】                     | ]                     |
| 《                     | <                     |
| 》                     | >                     |
| ——                     | --                    |
| ……                     | ...                   |
| ～                     | ~                     |

## Correct Example

```
# Module Description
这是一个正确的示例, 中文内容使用英文标点符号.

Parameters:
- name: 用户名
- age: 年龄
```

## Incorrect Example

```
# Module Description（错误）
这是一个错误的示例，中文内容使用全角标点符号。

Parameters：
- name: 用户名（错误）
```

## Applies To

- All content include Chinese.
