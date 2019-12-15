
names = %w(Taro Jiro Hana John Mike Sophy Bill Alex Mary Tom)
fnames = ["佐藤", "鈴木", "高橋", "田中"]
gnames = ["太郎", "次郎", "花子"]
0.upto(9) do |idx|
  Member.create(
    name: names[idx],
    full_name: "#{fnames[idx % 4]} #{gnames[idx % 3]}",
    email: "#{names[idx]}@example.com",
    birthday: "1981-12-01",
    administrator: (idx == 0),
    password: "wakatta!",
    password_confirmation: "wakatta!"
  )
end

0.upto(29) do |idx|
    Member.create(
      name: "John#{idx + 1}",
      full_name: "John Doe#{idx + 1}",
      email: "John#{idx+1}@example.com",
      birthday: "1981-12-01",
      administrator: false,
      password: "password",
      password_confirmation: "password"
    )
  end