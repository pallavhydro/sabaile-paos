# Memos on sed


## Replace a string in a file

`sed -i -e 's/AAA/BBB/g' <file>`

`Note`:
`i` is inline, `e` is expression, `s` is substitue, `g` is global.
\


## Delete a line from a file

`sed -i '1d' <file>`

where `1d` is the first line.
\


## Extract a range of lines from a file
`sed -i -n 2,4p somefile.txt`