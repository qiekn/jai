#import "Basic";

// ----------------------------------------------------------------------------: 1

PI :: #run compute_pi();

// calculate pi using the leibniz formula.
compute_pi :: () -> float {
   n := 1.0;
   s := 1.0;
   pi := 0.0;

   for 0..10000 {
      pi += 1.0 / (s*n);
      n += 2.0;
      s = -s;
   }

   return pi*4.0;
}

// ----------------------------------------------------------------------------: 2

ANOTHER_PI :: #run -> float {
   n, s := 1.0;
   pi := 0.0;

   for 0..10000 {
      pi += 1.0 / (s*n);
      n += 2.0;
      s = -s;
   }

   return pi*4.0;
}

main :: () {
   print("pi is %\n", PI);
   print("pi is %\n", ANOTHER_PI);
}
