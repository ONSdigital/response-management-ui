:: Batch file to start the mock follow-up and mock frame services on ports 8177 and 8178 respectively.
@echo off
start "Mock Follow-Up Service" cmd /c "cd .\followupservice && rackup -p 8177"
start "Mock Frame Service" cmd /c "cd .\frameservice && rackup -p 8178"
