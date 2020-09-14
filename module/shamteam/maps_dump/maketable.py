import csv
import sys

str = "maps = {"
#out = open('luatbl.lua', 'w')
with open(sys.path[0]+'/maps.csv', 'r') as f:
    for i, row in enumerate(csv.reader(f)):
        if i == 0:
            continue
        str += "{{code={0}, difficulty_hard={1}, difficulty_divine={2}, completed_hard=0, completed_divine=0, rounds_hard=0, rounds_divine=0}},".format(row[0], row[2], row[3])

str += "}"

print(str)
