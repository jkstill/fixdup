
<h2>fixdup</h2>

Two scripts that are used to clean up some address data.

<h3>Input data format:  </h3>

<pre>

      0 First Name
      1 Last Name
      2 Street Address
      3 City
      4 State
      5 ZipCode
      6 Phone
      7 Street Num
      8 Street Locater ( NW, SW, etc)
      9 Street Name
     10 Street Designator (ST, CT, DR, Drive, etc)
     11 Apt#
</pre>

Data may have multiple rows for a single address.

Combine them with the following rules:

<h3>Process the Data</h3>

 - one last name with multiple first names - print all first names in the same field
    - if there are 2+ phone numbers, print first name/phone for each individual
    - reduce phone numbers to one if all the same
  - if there are 2+ last name, create separate record for each last name
    - there may be multiple first names for a last name - treat the same as previously

</pre>

