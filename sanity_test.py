#!python
import sys
from base64 import b64decode
try:
    import mxnet as mx
    mx.img.imdecode(b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==')).asnumpy()
    print 'Test succeeded'
except:
    print 'Test failed'
    sys.exit(1)
