import tkinter

ds_w = 16
ds_hb = 1
ds_byteSize = 8
ds_prefix = "datalabel:"
ds_str = ".db %d "
ds_comment = ";Row %y Byte %b"

def main():
    root = tkinter.Tk()
    root.resizable(False, False)
    root.title("ARE LedMatrix")

    data = []
    for x in range(0, ds_w):
        data_col = []
        for y in range(0, ds_hb * ds_byteSize):
            dataVar = tkinter.StringVar()
            cb = tkinter.Checkbutton(root, variable=dataVar, onvalue="1", offvalue="0")
            cb.grid(row=y, column=x)
            cb.deselect()
            data_col.append(dataVar)
        data.append(data_col)

    root.mainloop()

    dataBytes = []
    comments = []
    for x in range(0, ds_w):
        for b in range(0, ds_hb):
            dataByte = "0b"
            for y in range(0, ds_byteSize):
                dataByte += data[x][y + b * ds_byteSize].get()
            dataBytes.append(dataByte)
            comments.append(ds_comment.replace("%y", str(x)).replace("%b", str(b)))
 
    dataText = ds_prefix + "\n"
    for d, c in zip(dataBytes, comments):
        dataText += ds_str.replace("%d", d) + c + "\n"

    print(dataText)

if __name__ == "__main__":
    main()