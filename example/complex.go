package main

import _ "hello"
import "world"

type x *[]string

var x = neat.desk(args...)
var n = neat.(type)
var u = x<<8 + y<<16

const (
	a = iota
	b
	c
	d
)

func testGetters() {
	owner := obj.Owner()
	if owner != user {
		obj.SetOwner(user)
	}

}

func testIf() {
	if err := file.Chmod(0664); err != nil {
		log.Print(err)
		return err
	}

	f, err := os.Open(name)
	if err != nil {
		return err
	}

	codeUsing(f)
}

func testFor() {
	sum := 0
	for i := 0; i < 10; i++ {
		sum += i
	}

}

func contents(filename string) (string, error) {
	var result []byte
	buf := make([]byte, 100)
	for {
		n, err := f.Read(buf[0:])
		result = append(result, buf[0:n]...)
		if err != nil {
			if err == io.EOF {
				break
			}

			return "", err
		}

	}

	return string(result), nil
}

func primaryExpressions() {
	a := [5]int{1, 2, 3, 4, 5}
	v, ok = x.(T)
	v, ok := x.(T)
	var v, ok = x.(T)
	math.Atan2(x, y)
	var pt *Point
	pt.Scale(3.5)
}

func (self *int) hello(a *[]string) (a, b int) {
	var (
		x, y *[]string = a
		z    int
	)
	n := 1
	n++
	s := x && y
	q = !z
	a := q[1:]
	b := q[:1]
	c := q[1:2:3]
	switch foo := foo(a...); foo > 0 {
	case x > 0:
		nice
	case q:
		s := "woot"
	default:
		true
	}

	for a, b := range Some {
		print(a)
	}

	for {
		some
	}

	for a, b := range Some {
		some
	}

	for a := 0; a < 10; a++ {
		some
	}

}

type X struct {
}

type X struct {
	x, y int
	_    float32
	A    *[]int
	*P.T4
}

type Point3D struct {
	x, y, z float64
}

func Greeting(prefix string, who ...string)

func test() {
	Greeting("hello:", "Joe", "Anna", "Eileen")
	s := []string{"James", "Jasmine"}
	Greeting("goodbye:", s...)
}

type T struct {
	a int
}

func (self T) Mv(a int) int {
	return 0
}

func (self *T) Mp(f float32) float32 {
	return 1
}

func methodExpression() {
	var t T
	t.Mv(7)
	T.Mv(t, 7)
	(T).Mv(t, 7)
	f1 := T.Mv
	f1(t, 7)
	f2 := (T).Mv
	f2(t, 7)
}

func testIf() {
	if x > max {
		x = max
	}

	if x := f(); x < y {
		return x
	} else if x > z {
		return z
	} else {
		return y
	}

}

func testSelectChan() {
	var (
		c, c1, c2, c3 chan int
	)
	var i1, i2 int
	select {
	case i1 = <-c1:
		print("received ", i1, " from c1")
	case c2 <- i2:
		print("sent ", i2, " to c2")
	case i3, ok := (<-c3):
		if ok {
			print("received ", i3, " from c3")
		} else {
			print("c3 is closed")
		}

	default:
		print("no communication")
	}

	for {
		select {
		case c <- 0:

		case c <- 1:

		}

		break
		continue
		fallthrough
	}

}

func testMap() {
	type a map[string]int
	var timeZone = map[string]int{"UTC": 0 * 60 * 60, "EST": -5 * 60 * 60, "CST": -6 * 60 * 60, "MST": -7 * 60 * 60, "PST": -8 * 60 * 60}
}

func testGoTo() {
	goto nice
nice:
	print("yes I'm")

}

func NewFile(fd int, name string) *File {
	if fd < 0 {
		return nil
	}

	f := File{fd, name, nil, 0}
	return &f
}

func testMapAllocation() {
	a := [...]string{Enone: "no error", Eio: "Eio", Einval: "invalid argument"}
	s := []string{Enone: "no error", Eio: "Eio", Einval: "invalid argument"}
	m := map[int]string{Enone: "no error", Eio: "Eio", Einval: "invalid argument"}
}

func Append(slice, data []byte) []byte {
	l := len(slice)
	if l+len(data) > cap(slice) {
		newSlice := make([]byte, (l+len(data))*2)
		copy(newSlice, slice)
		slice = newSlice
	}

	slice = slice[0 : l+len(data)]
	for i, c := range data {
		slice[l+i] = c
	}

	return slice
}

func Print() {
	t := &T{7, -2.35, "abc\tdef"}
	fmt.Printf("%v\n", t)
	fmt.Printf("%+v\n", t)
	fmt.Printf("%#v\n", t)
	fmt.Printf("%#v\n", timeZone)
}

func testGo() {
	f := func(a, b int) bool {
		nice
	}
	go f()
}

type Foxy interface {
	Read(b Buffer) bool
	Write(b Buffer) bool
	Close()
}

func inliner() {
	ls("-al", func(i, o string) {
		fmt.Println(i, o)
	})
}

func testForIn() {
	for a, b := range Some() {
		hereAllowed(in)
	}

	for a, b := range Some() {
		hereToo(in)
	}

}

func unfinished() {
	if a == b && b != c || (a > b && c > g) {
		doSome()
	}

}

func hereDoc() {
	a := "something"
	s := "This is awesome\nDarkness in the basement"
	fmt.Println(s)
}

func hereRegex() {
	s := `(?:[a-z][1-2]\s?)`
	s.MatchString("a1")
}

func doNotation() {
	lines.each(func(line string) {
		fmt.Println(line)
	})
	tokens.on("TERM", func(pos int) string {
		doSome(c, d)
	})
	x := func() {
		doSome()
	}
	go x()
	go func(a []string) {
		doSome(a)
	}(huge)
	stringSize := len(aString)
}
