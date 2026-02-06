@echo off
REM build_windows.cmd - command line ISE flow for XC9500XL CPLDs (Windows)
REM
REM You must have Xilinx ISE installed (e.g. 14.7) and the ISE bin directory in PATH.
REM Typical path example (adjust!):
REM   set PATH=C:\Xilinx\14.7\ISE_DS\ISE\bin\nt64;%PATH%
REM
REM Output: a1000_frontram.jed and a1000_frontram.svf

set PROJECT=a1000_frontram
set PART=XC9572XL-10-VQ64

echo [1/4] Synth (xst)
xst -ifn %PROJECT%.xst -ofn %PROJECT%.syr
if errorlevel 1 goto :err

echo [2/4] NGDBuild
ngdbuild -p %PART% -uc %PROJECT%.ucf %PROJECT%.ngc %PROJECT%.ngd
if errorlevel 1 goto :err

echo [3/4] Fit (cpldfit)
cpldfit -p %PART% -ofmt JED -optimize speed -loc on -tmd off %PROJECT%.ngd
if errorlevel 1 goto :err

echo [4/4] Generate SVF (hprep6)
hprep6 -s IEEE1149 -n %PROJECT% -i %PROJECT%
if errorlevel 1 goto :err

echo Done.
dir %PROJECT%.jed %PROJECT%.svf
exit /b 0

:err
echo Build failed with errorlevel %errorlevel%.
exit /b 1
