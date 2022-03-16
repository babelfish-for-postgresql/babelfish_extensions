# Isolation Tests

### Steps to run isolation tests locally:
1. Download antlr jar and generate parser files from grammer files.
	```
	java -Xmx500M -cp path/to/antlr/jar org.antlr.v4.Tool -Dlanguage=Python3 ./parser/*.g4 -visitor -no-listener
	```
2. Install antlr4-python3-runtime module.
	```
	pip install antlr4-python3-runtime
	```
3. In `config.txt` file, set
	```
	runIsolationTests = true
	compareWithFile = true
	Fill in the fileGenerator details
	inputFilesPath = ./input/isolation (if we want to run only isolation tests)
	```

4. Trigger the test run
	```
	python3 start.py
	```
