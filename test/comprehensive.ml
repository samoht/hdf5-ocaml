open Bigarray
open Hdf5_raw
open Hdf5_caml

let _FILE = "test.h5"
let _NX   = 5
let _NY   = 6

let () =
  let int32array = Array2.create int32 c_layout _NX _NY in
  for j = 0 to _NX - 1 do
    for i = 0 to _NY - 1 do
      int32array.{j, i} <- Int32.of_int (i + j)
    done
  done;
  let assert_array () =
    for j = 0 to _NX - 1 do
      for i = 0 to _NY - 1 do
        assert (int32array.{j, i} = Int32.of_int (i + j))
      done
    done
  in

  let file = H5f.create _FILE H5f.Acc.([ TRUNC ]) in
  assert (H5f.get_name file = _FILE);

  let group_a = H5g.create file "A" in
  let group_aa = H5g.create group_a "A" in
  let group_ab = H5g.create group_a "B" in

  let dataspace = H5s.create_simple [| _NX; _NY |] in

  let dataset_aaa = H5d.create group_aa "A" H5t.native_int dataspace in
  H5d.write dataset_aaa H5t.native_int H5s.all H5s.all int32array;
  H5d.close dataset_aaa;

  let dataset_aab = H5d.create group_aa "B" H5t.native_int dataspace in
  H5d.write dataset_aab H5t.native_int H5s.all H5s.all int32array;
  H5d.close dataset_aab;

  let dataset_aba = H5d.create group_ab "A" H5t.native_int dataspace in
  H5d.write dataset_aba H5t.native_int H5s.all H5s.all int32array;
  H5d.close dataset_aba;

  let dataset_abb = H5d.create group_ab "B" H5t.native_int dataspace in
  H5d.write dataset_abb H5t.native_int H5s.all H5s.all int32array;
  H5d.close dataset_abb;

  H5l.create_hard group_aa "A" file "AAA-link";
  H5l.create_soft "A/B/A" file "ABA-link";
  H5l.create_external "dest.h5" "A/A/B" file "AAB-link";

  H5g.close group_aa;
  H5g.close group_ab;
  H5g.close group_a;

  let dest = H5f.create "dest.h5" H5f.Acc.([ TRUNC ]) in
  let group_a = H5g.create dest "A" in
  let group_aa = H5g.create group_a "A" in

  let dataset_aab = H5d.create group_aa "B" H5t.native_int dataspace in
  H5d.write dataset_aab H5t.native_int H5s.all H5s.all int32array;
  H5d.close dataset_aab;

  H5g.close group_aa;
  H5g.close group_a;

  H5s.close dataspace;
  H5f.close dest;
  H5f.close file;

  let file = H5f.open_ _FILE H5f.Acc.([ RDWR ]) in
  let h5d = H5d.open_ file "AAA-link" in
  H5d.read h5d H5t.native_int H5s.all H5s.all int32array;
  H5d.close h5d;
  assert_array ();
  let h5d = H5d.open_ file "ABA-link" in
  H5d.read h5d H5t.native_int H5s.all H5s.all int32array;
  H5d.close h5d;
  assert_array ();
  let h5d = H5d.open_ file "AAB-link" in
  H5d.read h5d H5t.native_int H5s.all H5s.all int32array;
  H5d.close h5d;
  assert_array ();
  H5f.close file;

  let src = H5.open_rdwr _FILE in
  let dst = H5.open_rdwr "dest.h5" in
  H5.merge ~src ~dst;
  H5.close src;
  H5.close dst;

  let dest = H5f.open_ "dest.h5" H5f.Acc.([ RDONLY ]) in
  let group_a = H5g.open_ dest "A" in
  let group_aa = H5g.open_ group_a "A" in
  let dataset = H5d.open_ group_aa "A" in
  let dataspace = H5d.get_space dataset in
  let datatype = H5d.get_type dataset in
  let int32array = Array2.create int32 c_layout _NX _NY in
  H5d.read dataset datatype dataspace dataspace int32array;
  H5t.close datatype;
  H5s.close dataspace;
  H5d.close dataset;
  H5g.close group_aa;
  H5g.close group_a;
  H5f.close dest;

  let h5 = H5.create_trunc _FILE in
  let a = [| "abc"; "ABC"; "XYZABC" |] in
  H5.write_string_array h5 "a" a;
  let b = Array1.create Float64 C_layout 4 in
  for i = 0 to Array1.dim b - 1 do
    b.{i} <- (float) (i + 1)
  done;
  H5.write_float_array1 h5 "b" b;
  let c = Array2.create Float64 C_layout 3 4 in
  for i = 0 to Array2.dim1 c - 1 do
    for j = 0 to Array2.dim2 c - 1 do
      c.{i, j} <- (float) (i * 2 + j + 1)
    done
  done;
  H5.write_float_array2 h5 "c" c;
  let d = Array3.create Float64 C_layout 2 3 4 in
  for i = 0 to Array3.dim1 d - 1 do
    for j = 0 to Array3.dim2 d - 1 do
      for k = 0 to Array3.dim3 d - 1 do
        d.{i, j, k} <- (float) (i * 3 + j * 2 + k + 1)
      done
    done
  done;
  H5.write_float_array3 h5 "d" d;
  H5.close h5;
  let h5 = H5.open_rdonly _FILE in
  assert (a = H5.read_string_array h5 "a");
  assert (b = H5.read_float_array1 h5 "b");
  let data = Array1.create Float64 C_layout 10 in
  assert (data == H5.read_float_array1 h5 ~data "b");
  for i = 0 to Array1.dim b - 1 do
    assert (b.{i} = data.{i})
  done;
  assert (c = H5.read_float_array2 h5 "c");
  let data = Array2.create Float64 C_layout 10 4 in
  assert (data == H5.read_float_array2 h5 ~data "c");
  for i = 0 to Array2.dim1 c - 1 do
    for j = 0 to Array2.dim2 c - 1 do
      assert (c.{i, j} = data.{i, j})
    done
  done;
  assert (d = H5.read_float_array3 h5 "d");
  let data = Array3.create Float64 C_layout 10 3 4 in
  assert (data == H5.read_float_array3 h5 ~data "d");
  for i = 0 to Array3.dim1 d - 1 do
    for j = 0 to Array3.dim2 d - 1 do
      for k = 0 to Array3.dim3 d - 1 do
        assert (d.{i, j, k} = data.{i, j, k})
      done
    done
  done;
  H5.close h5;

  let h5 = H5.create_trunc _FILE in
  let d = H5.open_dir h5 "a" in
  H5.write_attribute_float d "f" 4.2;
  H5.write_attribute_int64 d "i64" 4L;
  H5.write_attribute_string d "s" "abc";
  H5.close d;
  H5.close h5;

  let h5 = H5.open_rdonly _FILE in
  let d = H5.open_dir h5 "a" in
  let f = H5.read_attribute_float d "f" in
  assert (f = 4.2);
  let i = H5.read_attribute_int64 d "i64" in
  assert (i = 4L);
  let s = H5.read_attribute_string d "s" in
  assert (s = "abc");
  H5.close d;
  H5.close h5
