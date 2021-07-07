from flask import Flask, request, url_for, redirect, render_template
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////tmp/test.db'
db = SQLAlchemy(app)


class Campaign(db.Model):
    address = db.Column(db.String(120), primary_key=True)
    title = db.Column(db.String(120), unique=True, nullable=False)

    def __repr__(self):
        return f'<Campaign title:{self.title} address:{self.address}>'


@app.route('/')
@app.route('/index')
def index():
    return render_template('index.html')


@app.route('/view_all_campaign', methods=['GET', 'POST'])
def view_all_campaign():
    if request.method == 'POST':
        print("in view_all_campaign post")
        all_campaign = Campaign.query.all()
        results = []
        for campaign_entry in all_campaign:
            results.append({'address': campaign_entry.address, 'title': campaign_entry.title})
        print(f'results: {results}')
        return {'results': results}
    return render_template('view_all_campaign.html')


@app.route('/new_campaign', methods=['GET', 'POST'])
def new_campaign():
    if request.method == 'POST':
        data = request.json
        print(request.json)

        new_campaign_entry = Campaign(address=data['address'], title=data['title'])
        db.session.add(new_campaign_entry)
        db.session.commit()

        return {'redirect': '/'}
    # show the form, it wasn't submitted
    return render_template('new_campaign.html')


@app.route('/get_campaign_address_by_name', methods=['GET', 'POST'])
def get_campaign_address_by_name():
    if request.method == 'POST':
        print(request.data)
        data = request.json
        print(data["campaign_name"])
        result = Campaign.query.filter_by(title=data["campaign_name"]).one()
        if result:
            return {'campaign_id': result.address}
        else:
            return {}


@app.route('/generate_keys', methods=['GET'])
def generate_keys():
    return render_template('generate_keys.html')


@app.route('/donate', methods=['GET'])
def donate():
    # show the form, it wasn't submitted
    return render_template('donate.html')


@app.route('/refund', methods=['GET'])
def refund():
    # show the form, it wasn't submitted
    return render_template('refund.html')


@app.route('/withdraw', methods=['GET'])
def withdraw():
    # show the form, it wasn't submitted
    return render_template('withdraw.html')


if __name__ == "__main__":
    db.create_all()
    all_campaign = Campaign.query.all()
    # Campaign.query.delete()
    db.session.commit()
    print(len(all_campaign))
    for c in all_campaign:
        print(c)

    # new_campaign_entry = Campaign(title='camp1', address="0xF6a27609e98E6A07FfbeFDc2c1B2a189929c358b")
    # db.session.add(new_campaign_entry)
    # db.session.commit()
    # new_campaign_entry = Campaign(title='camp2', address="0x2F447892ae3ac76305f738632F55e85786B3C9E9")
    # db.session.add(new_campaign_entry)
    # db.session.commit()
    # new_campaign_entry = Campaign(title='camp3', address="0xfD07315403c685dDAED475c9A749d30A822257fb")
    # db.session.add(new_campaign_entry)
    # db.session.commit()
    # {'title': 'camp2', 'address': '0x2F447892ae3ac76305f738632F55e85786B3C9E9'}
    # {'title': 'camp3', 'address': '0xfD07315403c685dDAED475c9A749d30A822257fb'}
    # new_campaign_entry = Campaign(address="ox123456", title="ohad campaign 1")
    # db.session.add(new_campaign_entry)
    # db.session.commit()
    # new_campaign_entry = Campaign(address="ox123457", title="ohad campaign 2")
    # db.session.add(new_campaign_entry)
    # db.session.commit()
    # new_campaign_entry = Campaign(address="ox123458", title="ohad campaign 3")
    # db.session.add(new_campaign_entry)
    # db.session.commit()
    # new_campaign_entry = Campaign(address="ox123459", title="ohad campaign 4")
    # db.session.add(new_campaign_entry)
    # db.session.commit()
    app.run(host="0.0.0.0", port=5000, debug=True)

