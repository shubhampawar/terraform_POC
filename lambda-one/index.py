import math
def handler(event,context):
    return math.pow(event['base'], event['exponent'])