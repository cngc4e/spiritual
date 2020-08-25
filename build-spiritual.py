import re
import os
import glob
import shutil

template = open("module.lua", "r", encoding="utf-8").read()

def getContentFromFile(target):
    if "*" in target:
        ret = []
        for f in glob.glob(target):
            ret.append(getContentFromFile(f))
            #print(f, getContentFromFile(f))
        return '\n'.join(ret)
    else:
        return open(target, "r", encoding="utf-8").read()

def thisShouldBeAnonymous(match):
    # fuck python
    target = match.group(1)
    return "--[[ " + target + " ]]--\n" \
        + getContentFromFile(target).strip() \
        + "\n--[[ end of " + target + " ]]--"
                       
reg = re.compile(r'@(?:include|spinclude) (\S+)', re.S)
def expand(content):
    if '@include' in content:
        content = reg.sub(thisShouldBeAnonymous, content)
        return expand(content)
    else:
        return content.strip()

# build translations
shutil.rmtree("translations-gen-spiritual", ignore_errors=True)
os.mkdir("translations-gen-spiritual")
files = glob.glob("translations-spiritual/*.txt")
for path in files:
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
        lang = os.path.splitext(os.path.basename(path))[0]
        wrt = "translations.{} = {{\n".format(lang)
        pairs = []
        for m in re.findall(r"(\S+)\s*=\s*\[\[([\S\s]*?)\]\]", content):
            key = m[0]
            val = m[1].strip().replace('\n', '\\n').replace('"', '\\"')
            pairs.append("\t{}=\"{}\"".format(key, val))
        wrt += ",\n".join(pairs)
        wrt += "\n}"
        with open("translations-gen-spiritual/{}.lua".format(lang), "w", encoding="utf-8") as fw:
            fw.write(wrt)

template = expand(template)

regremove = re.compile(r'(\n)?@(\S+)include (\S+)', re.S)
template = regremove.sub("", template)

with open("spiritual.lua", "w", encoding="utf-8") as f:
    f.write(template)
