if __name__=="__main__":
    arr:list[int]=[9,3,4,2,1,8]
    max:int=-1
    for i in arr:
        if i>max:
            max=i
    print(max)
