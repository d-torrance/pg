#########################################################################
#
#  Implement multiplication.
#
package Parser::BOP::multiply;
use strict; use vars qw(@ISA);
@ISA = qw(Parser::BOP);

#
#  Check that operand types are compatible for multiplication.
#
sub _check {
  my $self = shift;
  return if ($self->checkStrings());
  return if ($self->checkLists());
  return if ($self->checkNumbers());
  my ($ltype,$rtype) = $self->promotePoints('Matrix');
  if ($ltype->{name} eq 'Number' && $rtype->{name} =~ m/Vector|Matrix/) {
    $self->{type} = {%{$rtype}};
  } elsif ($ltype->{name} =~ m/Vector|Matrix/ && $rtype->{name} eq 'Number') {
    $self->{type} = {%{$ltype}};
  } elsif ($ltype->{name} eq 'Matrix' && $rtype->{name} eq 'Vector') {
    $self->checkMatrixSize($ltype,transposeVectorType($rtype));
  } elsif ($ltype->{name} eq 'Vector' && $rtype->{name} eq 'Matrix') {
    $self->checkMatrixSize(Value::Type('Matrix',1,$ltype),$rtype);
  } elsif ($ltype->{name} eq 'Matrix' && $rtype->{name} eq 'Matrix') {
    $self->checkMatrixSize($ltype,$rtype);
  } else {$self->Error("Operands of '*' are not of compatible types")}
}

#
#  Return the type of a vector as a column vector.
#
sub transposeVectorType {
  my $vtype = shift;
  Value::Type('Matrix',$vtype->{length},
     Value::Type('Matrix',1,$vtype->{entryType},formMatrix => 1),
     formMatrix =>1 );
}

#
#  Do the multiplication.
#
sub _eval {$_[1] * $_[2]}

#
#  Remove multiplication by one.
#  Reduce multiplication by zero to appropriately sized zero.
#  Factor out negatives.
#  Move a number from the right to the left.
#  Move a function apply from the left to the right.
#
sub _reduce {
  my $self = shift;
  return $self->{rop} if ($self->{lop}{isOne});
  return $self->{lop} if ($self->{rop}{isOne});
  return $self->makeZero($self->{rop},$self->{lop}) if ($self->{lop}{isZero});
  return $self->makeZero($self->{lop},$self->{rop}) if ($self->{rop}{isZero});
  return $self->makeNeg($self->{lop}{op},$self->{rop}) if ($self->{lop}->isNeg);
  return $self->makeNeg($self->{lop},$self->{rop}{op}) if ($self->{rop}->isNeg);
  $self->swapOps 
     if (($self->{rop}->class eq 'Number' && $self->{lop}->class ne 'Number') ||
        ($self->{lop}->class eq 'Function' && $self->{rop}->class ne 'Function'));
  return $self;
}

sub TeX {
  my ($self,$precedence,$showparens,$position) = @_;
  my $TeX; my $bop = $self->{def};
  my $mult = (defined($bop->{TeX}) ? $bop->{TeX} : $bop->{string});
  $mult = '\cdot ' if ($self->{lop}->class eq 'Number' && $self->{rop}->class eq 'Number');
  $self->{lop}->TeX($bop->{precedence},$bop->{leftparens},'left'). $mult .
  $self->{rop}->TeX($bop->{precedence},$bop->{rightparens},'right');
}

#########################################################################

1;
