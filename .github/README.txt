SSH ACCESS TO GITHUB ACTIONS INSTANCES

This commit is meant as a temporary measure to debug core dumps when the server crashes
during Github actions. Sometimes due to differences in memory allocatio between local
and Github actions, some crashes are not reproducible on local. In such cases, this
commit will enable ssh access to the Github instances so that engineers can use gdb to 
debug the core dumps.

Setup is very simple, just follow the instructions below:

1. After cherry-picking this commit, remove all the tests that you do not need from 
upgrade test schedules
2. Push the commit + schedules to your local branch
3. Keep an eye on the tests, once they have failed an ssh session will be set up
4. Find the ssh command from the test run and paste it in your cloud desktop. This 
will open a session on the Github instance.
5. Install gdb by running `sudo apt-get install gdb`
6. Debug the core dump by running 
`gdb /home/runner/postgrestarget/bin/postgres /var/coredumps/core-postgres-<pid>`
7. Exit the session by running `exit`. The workflow will not progress unless the ssh
session is exited. 

Note: The ssh session timeout is configured at a default of 60 minutes. To adjust it 
to your needs, please change the "timeout-minutes" field in the step with name "Setup
upterm session" in babelfish_extenions/.github/worflows/upgrade-test.yml.

Once the core dump has been debugged, please remember to REVERT THIS COMMIT. This should
not be checked in to the public repo. There is a step thay fails the workflow to make
sure that this cannot be checked in. 