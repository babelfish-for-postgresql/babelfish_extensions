import os

#returns a dictionary with all the configuration details
def read_config():
    with  open("config.txt", "r") as f:
        lines = f.readlines()
    lines = [ line.replace("\n", "") for line in lines ]
    configDict = {}
    for line in lines:
        if line.startswith("#") or len(line) < 1:
            continue
        else:
            data = line.split("=")
           
            for n, x in enumerate(data):
                data[n] = data[n].strip()
            
            configDict[data[0]] = data[1]
    
    #check and override key's value if already set in enviornment variables
    for key in configDict:
        if key in os.environ:
            configDict[key] = os.environ[key]
    
    return configDict

config_dict = read_config()

