# simple_multithread_application
Simple multithread application.

The task: write a program (in Delphi) that launches 2 identical threads. Threads run in parallel (simultaneously).
Each thread must write to the same file on disk (Result.txt) space-separated text records of prime numbers, sorted in ascending order and limited at the top by the number 1000000 (million).
Numbers in the file must not be duplicated or missing.
In a separate file of its own (Thread1.txt or Thread2.txt), each thread must save those numbers (also separated by a space) that it was he who wrote to the common file (Result.txt).

A prime number is a natural number that has exactly two distinct natural divisors: one and itself.
An example of how the files might look after the end of the program, if instead of 1000000 we use a limit of 20.
result.txt:
2 3 5 7 11 13 17 19
Thread1.txt:
2 3 5 13 19
Thread2.txt:
7 11 17
