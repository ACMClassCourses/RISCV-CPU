import os
import sys

isWin = sys.platform[:3] == 'win'
wslPrefix = 'ubuntu.exe run ' if isWin else ''

test_cases_dir = './testcase'
path_of_bit = 'C:/a.bit' # A Windows-style path is ok if you runs on Windows
excluded_test_cases = []

color_red = "\033[0;31m"
color_green = "\033[0;32m"
color_none = "\033[0m"


def program_device():
    os.system('vivado -nolog -nojournal -notrace -mode batch -source pd.tcl -tclarg ' + path_of_bit + ' > ' + ('NUL' if isWin else '/dev/null'))

def collect_test_cases():
    test_cases = []
    for f in os.listdir(test_cases_dir):
        if os.path.splitext(f)[1] == '.ans':
            test_cases.append(os.path.splitext(os.path.split(f)[1])[0])
    for s in excluded_test_cases:
        if s in test_cases: test_cases.remove(s)
    test_cases.sort()
    return test_cases

def main():
    program_device()
    test_cases = collect_test_cases()

    print('Build controller...')
    if os.system(wslPrefix + './ctrl/build.sh'): 
        print(color_red + 'Build Failed' + color_none)
        return
    print(color_green + 'Success' + color_none)

    for t in test_cases:
        print('Testing ' + t + ': ')
        if os.system(wslPrefix + './autorun_fpga.sh ' + t): 
            print(color_red + 'Test Failed' + color_none)
            continue
        if os.system(wslPrefix + 'diff ./test/test.ans ./test/test.out > diff.out'): 
            print(color_red + 'Wrong Answer' + color_none)
            continue
        print(color_green + 'Accepted' + color_none)

if __name__ == '__main__':
    main()