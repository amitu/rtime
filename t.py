import os
import sys
import subprocess


def o(folder, cmd):
    proc = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE, cwd=folder)
    proc.wait()
    return proc.stdout.read(), proc.returncode


def gsubify2(pth):
    pth = pth.rstrip("/")

    dst = ("vendor/src/%s" % pth)
    print("mkdir -p", dst)
    dstdad = dst.rsplit("/", 1)[0]

    giturl = "https://%s.git" % pth
    gclone = "git clone %s" % giturl
    print dstdad, pth, giturl, gclone

    try:
        os.makedirs(dst)
    except OSError:
        pass

    git, code = o(dstdad, gclone)
    if code != 0:
        print(git)
        return

    commit, code = o(dst, "git rev-parse HEAD")
    if code != 0:
        print(commit)
        return
    commit = commit.strip()

    open(dst + ".gsub", "w").write("%s %s\n" % (giturl, commit))
    o(".", "git add " + dst + ".gsub -f")
    open(".gitignore", "a+").write(dst + "/\n")


def main():
    gsubify2(sys.argv[1])


main()
