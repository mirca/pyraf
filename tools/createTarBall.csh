#!/bin/csh -f
#
if ($#argv > 1) then
   echo "Usage: $0 [dev]"
   exit 1
endif
set isdev = 0
if ($#argv == 1) then
   if ($argv[1] == "dev") then
      set isdev = 1
   endif
endif

set workDir = ~/.pyraf_tar_ball
echo Creating work area: $workDir
/bin/rm -rf $workDir
mkdir $workDir
cd $workDir
if ($status != 0) then
   exit 1
endif
#
if ($isdev == 1) then
   set pyr = "pyraf-dev"
   set co_pyraf = 'co -q -r HEAD http://svn6.assembla.com/svn/pyraf/trunk'
   set co_dist  = 'co -q -r HEAD https://svn.stsci.edu/svn/ssb/stsci_python/stsci_python/trunk/distutils'
   set co_tools = 'co -q -r HEAD https://svn.stsci.edu/svn/ssb/stsci_python/stsci_python/trunk/tools'
else
   set pyr = "pyraf-1.11"
   echo -n 'What will the pyraf dir name be? ('$pyr'): '
   set ans = $<
   if ($ans != '') then
      set pyr = $ans
   endif
   set brn = "release_2011_07"
   echo -n 'What is branch name? ('$brn'): '
   set ans = $<
   if ($ans != '') then
      set brn = $ans
   endif
   set co_pyraf = "co -q http://svn6.assembla.com/svn/pyraf/branches/$brn"
   set co_dist  = "co -q https://svn.stsci.edu/svn/ssb/stsci_python/stsci_python/branches/$brn/distutils"
   set co_tools = "co -q https://svn.stsci.edu/svn/ssb/stsci_python/stsci_python/branches/$brn/tools"
endif

# get all source via SVN
echo "Downloading source for: $pyr"
svn $co_pyraf $pyr
if ($status != 0) then
   echo ERROR svn-ing pyraf
   exit 1
endif

# get extra pkgs into a subdir
cd $workDir/$pyr
mkdir required_pkgs
cd $workDir/$pyr/required_pkgs
echo "Downloading source for: tools, distutils"
svn $co_dist distutils
if ($status != 0) then
   echo ERROR svn-ing distutils
   exit 1
endif
svn $co_tools tools
if ($status != 0) then
   echo ERROR svn-ing tools
   exit 1
endif
echo This build will show a version number of:
grep '__version__ *=' $workDir/$pyr/lib/pyraf/__init__.py

# remove svn dirs
cd $workDir/$pyr
/bin/rm -rf `find . -name '.svn'`
if ($status != 0) then
   echo ERROR cleaning out .svn dirs
   exit 1
endif

# edit setup to comment our pyfits requirement (we dont need it for pyraf)
cd $workDir/$pyr/required_pkgs/tools
/bin/cp setup.cfg setup.cfg.orig
cat setup.cfg.orig | sed 's/^\(  *pyfits .*\)/#\1/' > setup.cfg
diff setup.cfg.orig setup.cfg

# edit pyraf setup stuff to use the required_pkgs sub-dir
cd $workDir/$pyr
# change line to: find-links = required_pkgs
/bin/cp setup.cfg setup.cfg.orig
cat setup.cfg.orig | sed 's/^ *find-links *=.*/find-links = required_pkgs/' > setup.cfg
diff setup.cfg.orig setup.cfg
# change line to use: os.path.abspath("required_pkgs/distutils/lib")
/bin/cp setup.py setup.py.orig
cat setup.py.orig | sed 's/^\( *stsci_distutils *=\).*/\1 os.path.abspath("required_pkgs"+os.sep+"distutils"+os.sep+"lib")/' > setup.py
diff setup.py.orig setup.py

# tar and zip it
cd $workDir
tar cf $pyr.tar $pyr
if ($status != 0) then
   echo ERROR tarring up
   exit 1
endif
gzip $pyr.tar
if ($status != 0) then
   echo ERROR gzipping
   exit 1
endif
#
echo DONE
