!This is a program that will read in a vector from totalsucc.bin, then check
!which bin it falls into.  It does this for an entire data set, counting
!at each step how many points fall into each bin.  It then prints the
!final density histogram count.

!INPUT: The dimension of the data set; the number of data points to read;
!number of bins desired.

program bincounter
  use types, only : dp
  use features, only : newunit
  use sorters, only : locate
  implicit none

  integer, dimension(:,:), allocatable :: bins
  real(dp), dimension(:), allocatable :: binsize
  integer :: binnumb, u, tot, i, j, change, start, dimn
  integer, dimension(:,:), allocatable :: inttable
  real(dp), dimension(:,:), allocatable :: table, binsreal
  character(len=32) :: filename, fileform

  namelist / sample / binnumb, dimn, tot, filename, fileform

  !Read the namelist.
  open(unit=newunit(u),file="binparams.txt",delim="apostrophe", status="old")
  read(u, nml=sample)
  close(u)

  !Make the arrays.
  allocate(table(tot,dimn))
  allocate(inttable(tot,dimn))
  if (fileform=="*") then
    open(unit=newunit(u), file=filename)
  else
    open(unit=newunit(u), file=filename, form=fileform)
  end if
  do i=1,tot
    if (fileform=="*") then
      read(u,*) (table(i,j),j=1,dimn)
    else
      read(u) (table(i,j),j=1,dimn)
    end if
  end do
  close(u)

  !Get bin size for each dimension.
  allocate(binsize(dimn))
  do i=1,dimn
    binsize(i)=(maxval(table(:,i))-minval(table(:,i)))/real(binnumb)
    print*, "max in dimn ", i ," is ",maxval(table(:,i))
    print*, "min in dimn ", i ," is ",minval(table(:,i))
  end do

  !Make bins table.
  allocate(bins(binnumb**dimn,dimn+1))
  !Load last dimn.
  bins=0
  do j=0,dimn-1
     do i=1,size(bins,1)
       change=binnumb**j
       bins(i,dimn-j)=mod((i-1)/change,binnumb)+1   !Note int div
     end do
  end do
  !Sort into bins.
  do i=1,size(table,2)
    inttable(:,i)=ceiling((table(:,i)-minval(table(:,i)))/binsize(i))
  end do
  do i=1,size(inttable,1)
    call locate(bins,inttable(i,1),start)
    if (start==0) start=1
    do j=start,size(bins,1)
      if (all(bins(j,1:dimn)==inttable(i,:))) then
        bins(j,size(bins,2))=bins(j,size(bins,2))+1
        exit
      else if (bins(j,1)>inttable(i,1)) then
        exit
      end if
    end do
  end do

  !Print the bin information.
  allocate(binsreal(size(bins,1),dimn))
  do i=1,dimn
    binsreal(:,i)=bins(:,i)*binsize(i)+minval(table(:,i))
  end do
  open(unit=newunit(u),file="count_with_bins.txt")
  do i=1, size(binsreal,1)
    write(u,fmt=*),(binsreal(i,j),j=1,dimn), bins(i,size(bins,2))
  end do
  close(u)
  !If 2D, then also print info for plotting with Mathematica.  This mimics the
  !output from BinCounts[data,{0,max,binsize},{0,max,binsize}].
  if (dimn==2) then
    open(unit=newunit(u),file="bincounts.txt")
    do i=0, binnumb-1
      write(u,fmt=*), (bins(j+i*binnumb,3),j=1,binnumb)
    end do
    close(u)
  end if

end program bincounter
