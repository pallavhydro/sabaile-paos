# Memos on useful tricks and workarounds on R


## Get only the core data from an xts

```
datatable = coredata(my_xts)
```
\

## Control location on a date axis

```
# Position at 50% to 90% of the x-axis 
# (type = 1 is compatible for dates in the quantile function call):

xmin = quantile(date_vector, 0.5, type = 1)

xmax = quantile(date_vector, 0.9, type = 1)

```
\



