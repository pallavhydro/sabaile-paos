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


## Installing r and r packages via conda

```
conda create -y --prefix ./r_my_version
conda install r r-essentials --channel conda-forge
conda install r-<package-name> --channel conda-forge
```
\

## Write table to a file

```
write.table(table1, file="table1.txt", sep=",", quote = F, row.names = F)
```
\

## Add lines of information to a file

```
cat(string1, file = "string1.txt", append = TRUE)
```
\


