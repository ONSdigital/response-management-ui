:: Batch file to start the mock follow-up and mock frame services on posts 8177 and 8178 respectively.
@echo off
start "Mock Follow-Up Service" cmd /c "cd D:\code\beyond-soa-demo\beyondweb\mock\followupservice && rackup -p 8177"
start "Mock Frame Service" cmd /c "cd D:\code\beyond-soa-demo\beyondweb\mock\frameservice && rackup -p 8178"
start "Mock Product Service" cmd /c "cd D:\code\beyond-soa-demo\beyondweb\mock\productservice && rackup -p 8170"
