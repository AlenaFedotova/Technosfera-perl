use utf8;
package Local::Schema::Result::Comment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Local::Schema::Result::Comment

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<comment>

=cut

__PACKAGE__->table("comment");

=head1 ACCESSORS

=head2 commentor

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 50

=head2 post_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "commentor",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 50 },
  "post_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</post_id>

=item * L</commentor>

=back

=cut

__PACKAGE__->set_primary_key("post_id", "commentor");

=head1 RELATIONS

=head2 commentor

Type: belongs_to

Related object: L<Local::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "commentor",
  "Local::Schema::Result::User",
  { username => "commentor" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 post

Type: belongs_to

Related object: L<Local::Schema::Result::Post>

=cut

__PACKAGE__->belongs_to(
  "post",
  "Local::Schema::Result::Post",
  { id => "post_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2016-11-13 18:17:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:i/PkLGfmJsiIqytOwbbqSA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
