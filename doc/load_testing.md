# Load testing

To set up a load test that will make fake users submit encrypted ballot files, you need to generate these ballot files in advance. A script which does this automatically is available at `tests/load_testing_set_up.py`. Here is an example of usage.

## Set up a load test

### Start the server

If the Application Under Test is your local Belenios server:

In a local terminal, start your Belenios server:

```
BELENIOS_SENDMAIL=/path/to/tests/tools/sendmail_fake_to_static.sh demo/run-server.sh
```

Else (the Application Under Test is a distant Belenios server):

SSH into the server machine and start the Belenios server by executing the same kind of command, making sure that the fake sendmail command writes into a text file that is publicly accessible by a URL.

Make sure you have an administrator user account on this Belenios server, so that you can create an election.

### Execute the script that creates the election and generates ballot files and the aggregated votes CSV file

In another local terminal, run:

```
cd /path/to/belenios/git/repository
source venv/bin/activate
```

If the Application Under Test is your local Belenios server:

Execute the script:

````
USE_HEADLESS_BROWSER=0 SENT_EMAILS_TEXT_FILE_ABSOLUTE_PATH=/path/to/_build/src/static/mail.txt FAKE_SENDMAIL_EXECUTABLE_FILE_PATH_RELATIVE_TO_GIT_REPOSITORY=tests/tools/sendmail_fake_to_static.sh FAKE_SENT_EMAILS_FILE_RELATIVE_URL=static/mail.txt python ./tests/load_testing_set_up.py
````

where `sendmail_fake_to_static.sh` contains something like this:

```
#!/bin/sh
exec cat >> /path/to/belenios/git/repository/_build/src/static/mail.txt
```

Else (the Application Under Test is a distant Belenios server):

Execute the script:

```
SERVER_URL=https://belenios2.lhs.loria.fr USE_HEADLESS_BROWSER=0 LOGIN_MODE=public ADMINISTRATOR_USERNAME=your_belenios_administrator_user_login ADMINISTRATOR_PASSWORD=your_belenios_administrator_user_password SENT_EMAILS_TEXT_FILE_ABSOLUTE_PATH=/path/to/belenios/git/repository/_build/src/static/mail.txt FAKE_SENT_EMAILS_FILE_RELATIVE_URL=mail/mails.txt FAKE_SENDMAIL_EXECUTABLE_FILE_PATH_RELATIVE_TO_GIT_REPOSITORY=tests/tools/sendmail_fake_to_static.sh python ./tests/load_testing_set_up.py
```

This prints in the output several things including the ID of the election. Copy it for later. This also creates files `voter_row_{i}_crypted_ballot.json`, `voter_row_{i}_privcred.txt`, `voter_row_{i}_uncrypted_ballot.json` for each voter `{i}`. This also creates file `all_votes.csv`.

## Execute the load test with a low amount of virtual users

You can now open JMeter, load the load testing script, set its configuration parameters (server URL and election ID), and execute the load test and check that everything works as expected.

## Execute a real load test by increasing the number of virtual users

Now, you can run the redo the whole process with a higher number of voters (change the value of `NUMBER_OF_INVITED_VOTERS` and `NUMBER_OF_VOTING_VOTERS` when executing the python script). When executing a real load test, it is recommended to execute the CLI version of Jmeter instead of its GUI.