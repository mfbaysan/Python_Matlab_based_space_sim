import matlab.engine
import matlab.engine as ml

print('test')

eng = matlab.engine.start_matlab()

t = eng.isprime(17)
a = 2
b = 3
c = eng.plus(a, b)
eng.quit()
print(t, c)





