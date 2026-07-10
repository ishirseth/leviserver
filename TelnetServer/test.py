n = int("5")
if n > 1000000000000:
    print("~Argument is too large\r\n")
if n < 2:
    print("~Not prime\r\n")
for i in range(2, int(n**0.5) + 1):
    if n % i == 0:
        print("~Not prime\r\n")
print("~Prime\r\n")

